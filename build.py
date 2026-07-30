#!/usr/bin/env python3
"""
build.py — the static site generator for epistemic-ontology.net.

Why this exists
---------------
The site used to be three hand-maintained HTML files with the header, footer and
metadata copy-pasted between them, and every version number typed by hand. That
drifted: the site advertised Record Ontology v0.5.0 for weeks after the ontology
had moved to v0.6.0. So the rule here is:

    anything that can be read off the RDF is read off the RDF.

Version strings, ontology titles, licences, imports and term counts are all
extracted from the staged Turtle in `ontology-dist/` with rdflib. Prose lives in
`content/` as Markdown with YAML front matter. Layout lives once, in
`templates/`. The output tree `site/` is disposable — it is rebuilt from scratch
on every run and is what gets rsynced to the server.

Usage
-----
    python3 build.py            # build into site/
    python3 build.py --check    # build, then fail if anything looks wrong
    python3 build.py --serve    # build and serve on :8000
"""

from __future__ import annotations

import argparse
import html
import re
import shutil
import sys
import unicodedata
from dataclasses import dataclass, field
from datetime import date, datetime, timezone
from pathlib import Path
from typing import Any, Iterable

try:
    import yaml
    from jinja2 import Environment, FileSystemLoader, StrictUndefined
    from markdown_it import MarkdownIt
except ImportError as exc:  # pragma: no cover - startup guard
    sys.exit(f"error: missing build dependency ({exc.name}). Run: pip install -r requirements.txt")

ROOT = Path(__file__).resolve().parent
CONTENT = ROOT / "content"
TEMPLATES = ROOT / "templates"
STATIC = ROOT / "static"
DIST = ROOT / "ontology-dist"
OUT = ROOT / "site"

BUILD_DATE = datetime.now(timezone.utc)


# ---------------------------------------------------------------------------
# Front matter
# ---------------------------------------------------------------------------

FM_RE = re.compile(r"\A---\r?\n(.*?)\r?\n---\r?\n?(.*)\Z", re.S)


def read_front_matter(path: Path) -> tuple[dict[str, Any], str]:
    """Split a `---` YAML front-matter block off the top of a Markdown file."""
    text = path.read_text(encoding="utf-8")
    match = FM_RE.match(text)
    if not match:
        raise SystemExit(f"error: {path.relative_to(ROOT)} has no YAML front matter")
    meta = yaml.safe_load(match.group(1)) or {}
    if not isinstance(meta, dict):
        raise SystemExit(f"error: {path.relative_to(ROOT)} front matter is not a mapping")
    return meta, match.group(2)


def require(meta: dict[str, Any], keys: Iterable[str], path: Path) -> None:
    missing = [k for k in keys if not meta.get(k)]
    if missing:
        raise SystemExit(
            f"error: {path.relative_to(ROOT)} is missing front-matter key(s): {', '.join(missing)}"
        )


# ---------------------------------------------------------------------------
# Syntax highlighting (build-time, so the browser ships no JS for it)
# ---------------------------------------------------------------------------

def _scanner(spec: list[tuple[str, str]]) -> re.Pattern[str]:
    return re.compile("|".join(f"(?P<{name}>{pat})" for name, pat in spec), re.S)


TURTLE = _scanner([
    ("c", r"#[^\n]*"),
    ("s", r'"""(?:\\.|[^\\])*?"""|"(?:\\.|[^"\\])*"'),
    ("k", r"@prefix\b|@base\b|\ba\b(?=\s)"),
    ("i", r"<[^>\s]*>"),
    ("l", r"@[a-zA-Z-]+|\^\^"),
    ("p", r"[A-Za-z][\w.-]*:[\w.%-]*"),
    ("n", r"\b\d[\d.eE+-]*\b"),
])

BASH = _scanner([
    ("c", r"#[^\n]*"),
    ("s", r'"(?:\\.|[^"\\])*"|\'[^\']*\''),
    ("k", r"^\s*(?:sudo|curl|python3?|make|git|rsync|scp|ssh|cp|ln|systemctl|certbot|pip|nginx|cd|grep)\b"),
    ("l", r"(?<=\s)-{1,2}[A-Za-z][\w-]*"),
])

PYTHON = _scanner([
    ("c", r"#[^\n]*"),
    ("s", r'"""(?:\\.|[^\\])*?"""|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\''),
    ("k", r"\b(?:from|import|def|class|return|if|else|elif|for|while|with|as|not|in|is|and|or|None|True|False|lambda|yield|raise|try|except|finally)\b"),
    ("n", r"\b\d[\d.eE+-]*\b"),
])

BIBTEX = _scanner([
    ("c", r"%[^\n]*"),
    ("k", r"@\w+"),
    ("s", r"\{[^{}]*\}"),
    ("p", r"^\s*\w+(?=\s*=)"),
])

LANGS = {
    "turtle": TURTLE, "ttl": TURTLE, "sparql": TURTLE,
    "bash": BASH, "sh": BASH, "shell": BASH, "console": BASH,
    "python": PYTHON, "py": PYTHON,
    "bibtex": BIBTEX, "bib": BIBTEX,
}


def highlight(code: str, lang: str) -> str:
    """Wrap recognised tokens in spans. Everything is escaped exactly once."""
    scanner = LANGS.get((lang or "").lower())
    if scanner is None:
        return html.escape(code)
    out: list[str] = []
    pos = 0
    for m in scanner.finditer(code):
        if m.start() > pos:
            out.append(html.escape(code[pos:m.start()]))
        kind = m.lastgroup or ""
        out.append(f'<span class="t-{kind}">{html.escape(m.group())}</span>')
        pos = m.end()
    out.append(html.escape(code[pos:]))
    return "".join(out)


# ---------------------------------------------------------------------------
# Markdown
# ---------------------------------------------------------------------------

def slugify(text: str) -> str:
    text = unicodedata.normalize("NFKD", text)
    text = "".join(c for c in text if not unicodedata.combining(c))
    text = re.sub(r"[^\w\s-]", "", text.lower()).strip()
    return re.sub(r"[\s_]+", "-", text) or "section"


def _fence(self, tokens, idx, options, env):  # noqa: ANN001 - markdown-it signature
    token = tokens[idx]
    lang = (token.info or "").strip().split()[0] if token.info else ""
    body = highlight(token.content, lang)
    cls = f' class="language-{html.escape(lang)}"' if lang else ""
    return f'<pre{cls}><code>{body}</code></pre>\n'


def make_markdown() -> MarkdownIt:
    # linkify is off deliberately: it needs linkify-it-py, and bare URLs in this
    # content are namespace IRIs that should stay literal rather than become
    # clickable links to themselves.
    md = MarkdownIt("gfm-like", {"linkify": False, "typographer": True})
    md.disable("linkify")
    md.add_render_rule("fence", _fence)
    return md


MD = make_markdown()


@dataclass
class Rendered:
    html: str
    toc: list[dict[str, Any]] = field(default_factory=list)
    words: int = 0


def render_markdown(text: str, toc_levels: tuple[str, ...] = ("h2", "h3")) -> Rendered:
    """Render Markdown, giving every heading a stable id and collecting a TOC."""
    tokens = MD.parse(text)
    toc: list[dict[str, Any]] = []
    seen: dict[str, int] = {}
    for i, token in enumerate(tokens):
        if token.type != "heading_open":
            continue
        inline = tokens[i + 1] if i + 1 < len(tokens) else None
        title = inline.content if inline is not None else ""
        base = slugify(re.sub(r"`|\*|\[|\]\([^)]*\)", "", title))
        seen[base] = seen.get(base, 0) + 1
        anchor = base if seen[base] == 1 else f"{base}-{seen[base]}"
        token.attrSet("id", anchor)
        if token.tag in toc_levels:
            toc.append({"id": anchor, "title": title, "level": int(token.tag[1])})
    body = MD.renderer.render(tokens, MD.options, {})
    return Rendered(html=body, toc=toc, words=len(text.split()))


# ---------------------------------------------------------------------------
# Ontology metadata, straight from the Turtle
# ---------------------------------------------------------------------------

def ontology_metadata(ttl: Path, namespace: str) -> dict[str, Any]:
    """Read version, title, licence, imports and term counts out of a Turtle file.

    This is the anti-drift mechanism: nothing about an ontology's identity is
    retyped in the site content.
    """
    try:
        from rdflib import Graph, RDF, OWL, RDFS
        from rdflib.namespace import DCTERMS
    except ImportError:  # pragma: no cover
        sys.exit("error: rdflib is required to read ontology metadata (pip install -r requirements.txt)")

    graph = Graph()
    try:
        graph.parse(ttl, format="turtle")
    except Exception as exc:  # noqa: BLE001 - surface the parse error verbatim
        raise SystemExit(f"error: cannot parse {ttl.relative_to(ROOT)}: {exc}") from exc

    subjects = list(graph.subjects(RDF.type, OWL.Ontology))
    if not subjects:
        raise SystemExit(f"error: {ttl.relative_to(ROOT)} declares no owl:Ontology")
    subject = subjects[0]

    raw_version = str(graph.value(subject, OWL.versionInfo) or "")
    version, _, note = raw_version.partition("—")
    counts = {
        "classes": len({s for s in graph.subjects(RDF.type, OWL.Class) if str(s).startswith(namespace)}),
        "object_properties": len({s for s in graph.subjects(RDF.type, OWL.ObjectProperty)
                                  if str(s).startswith(namespace)}),
        "datatype_properties": len({s for s in graph.subjects(RDF.type, OWL.DatatypeProperty)
                                    if str(s).startswith(namespace)}),
        "individuals": len({s for s in graph.subjects(RDF.type, OWL.NamedIndividual)
                            if str(s).startswith(namespace)}),
    }
    counts["properties"] = counts["object_properties"] + counts["datatype_properties"]
    return {
        "iri": str(subject),
        "version": version.strip().strip('"') or "unversioned",
        "version_note": note.strip(),
        "title": str(graph.value(subject, DCTERMS.title) or ""),
        "comment": str(graph.value(subject, RDFS.comment) or ""),
        "license": str(graph.value(subject, DCTERMS.license) or ""),
        "imports": sorted(str(o) for o in graph.objects(subject, OWL.imports)),
        "triples": len(graph),
        "counts": counts,
    }


# ---------------------------------------------------------------------------
# Content model
# ---------------------------------------------------------------------------

@dataclass
class Page:
    url: str
    title: str
    description: str
    body: str
    template: str
    meta: dict[str, Any] = field(default_factory=dict)
    toc: list[dict[str, Any]] = field(default_factory=list)
    updated: date | None = None
    priority: str = "0.5"


EMPTY_RDF: dict[str, Any] = {
    "iri": "", "version": "", "version_note": "", "title": "", "comment": "",
    "license": "", "imports": [], "triples": 0, "counts": {},
}


def load_ontologies() -> list[dict[str, Any]]:
    ontologies = []
    for path in sorted((CONTENT / "ontologies").glob("*.md")):
        meta, body = read_front_matter(path)
        require(meta, ("slug", "title", "namespace", "prefix", "summary"), path)
        slug = meta["slug"]
        dist = DIST / slug
        primary = meta.get("primary_file")
        files = meta.get("files") or []
        if primary is None and files:
            primary = files[0]["file"]
        rdf: dict[str, Any] = dict(EMPTY_RDF)
        if primary:
            ttl = dist / primary
            if not ttl.exists():
                raise SystemExit(
                    f"error: {path.relative_to(ROOT)} points at missing {ttl.relative_to(ROOT)}"
                    " — run `make stage` first"
                )
            rdf = ontology_metadata(ttl, meta["namespace"])
        for entry in files:
            src = dist / entry["file"]
            entry["exists"] = src.exists()
            entry["bytes"] = src.stat().st_size if entry["exists"] else 0
            if not entry["exists"]:
                print(f"  warn: {slug}/{entry['file']} is not staged", file=sys.stderr)
        rendered = render_markdown(body)
        ontologies.append({
            "badges": [], "repo": "", "license": None, "companion": False,
            "order": 99, "cite_year": BUILD_DATE.year,
            "cite_key": f"{slug.replace('-', '')}{BUILD_DATE.year}",
            "cite_title": meta["title"],
            **meta,
            "rdf": rdf,
            "files": files,
            "body": rendered.html,
            "toc": rendered.toc,
            "url": f"/{slug}/",
        })
    ontologies.sort(key=lambda o: (o.get("order", 99), o["title"]))
    return ontologies


def load_posts() -> list[dict[str, Any]]:
    posts = []
    for path in sorted((CONTENT / "blog").glob("*.md")):
        meta, body = read_front_matter(path)
        require(meta, ("title", "date", "summary"), path)
        if meta.get("draft"):
            continue
        published = meta["date"]
        if isinstance(published, datetime):
            published = published.date()
        if not isinstance(published, date):
            raise SystemExit(f"error: {path.relative_to(ROOT)} has a non-date `date:`")
        slug = meta.get("slug") or re.sub(r"^\d{4}-\d{2}-\d{2}-", "", path.stem)
        rendered = render_markdown(body)
        posts.append({
            "reading": [],
            **meta,
            "date": published,
            "updated": meta.get("updated") or published,
            "slug": slug,
            "url": f"/blog/{slug}/",
            "body": rendered.html,
            "toc": rendered.toc,
            "tags": meta.get("tags") or [],
            "reading_time": max(1, round(rendered.words / 200)),
            "source": str(path.relative_to(ROOT)),
        })
    # `seq` breaks ties within a day, so a batch published together can still be
    # given a deliberate reading order.
    posts.sort(key=lambda p: (p["date"], p.get("seq", 0), p["slug"]), reverse=True)
    return posts


def load_pages() -> list[dict[str, Any]]:
    pages = []
    for path in sorted((CONTENT / "pages").glob("*.md")):
        meta, body = read_front_matter(path)
        require(meta, ("title", "slug"), path)
        rendered = render_markdown(body)
        pages.append({
            "lead": "", "description": "", "headline": meta["title"],
            **meta,
            "body": rendered.html,
            "toc": rendered.toc,
            "url": "/" if meta["slug"] == "index" else f"/{meta['slug']}/",
        })
    return pages


# ---------------------------------------------------------------------------
# Emit
# ---------------------------------------------------------------------------

def write(url: str, text: str) -> Path:
    """Write a document at a clean URL (`/blog/` -> `site/blog/index.html`)."""
    rel = url.lstrip("/")
    target = OUT / (rel + "index.html" if url.endswith("/") else rel)
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(text, encoding="utf-8")
    return target


def copy_tree(src: Path, dst: Path) -> int:
    count = 0
    for item in sorted(src.rglob("*")):
        if item.is_dir() or item.name.startswith("."):
            continue
        target = dst / item.relative_to(src)
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(item, target)
        count += 1
    return count


def build() -> dict[str, Any]:
    config = yaml.safe_load((CONTENT / "site.yaml").read_text(encoding="utf-8"))
    base_url = config["base_url"].rstrip("/")

    env = Environment(
        loader=FileSystemLoader(TEMPLATES),
        autoescape=True,
        undefined=StrictUndefined,
        trim_blocks=True,
        lstrip_blocks=True,
    )
    env.filters["datefmt"] = lambda d, fmt="%-d %B %Y": d.strftime(fmt)
    env.filters["isodate"] = lambda d: d.isoformat()
    env.filters["rfc3339"] = lambda d: (
        d.isoformat() if isinstance(d, datetime)
        else datetime(d.year, d.month, d.day, 12, tzinfo=timezone.utc).isoformat()
    )
    env.filters["absurl"] = lambda u: u if u.startswith("http") else base_url + u
    env.filters["kb"] = lambda n: f"{n / 1024:.1f} kB" if n else "—"
    # One source of truth for tag URLs, shared with the writer below, so a tag
    # containing punctuation cannot link somewhere that was never written.
    env.filters["tagurl"] = lambda t: f"/blog/tag/{slugify(t)}/"

    ontologies = load_ontologies()
    posts = load_posts()
    pages = load_pages()

    tags: dict[str, list[dict[str, Any]]] = {}
    for post in posts:
        for tag in post["tags"]:
            tags.setdefault(tag, []).append(post)

    shared = {
        "site": config,
        "base_url": base_url,
        "ontologies": ontologies,
        "posts": posts,
        "tags": dict(sorted(tags.items())),
        "now": BUILD_DATE,
        "build_year": BUILD_DATE.year,
    }

    written: list[Path] = []

    # Home
    home = next((p for p in pages if p["slug"] == "index"), None)
    if home is None:
        raise SystemExit("error: content/pages/index.md is required")
    written.append(write("/", env.get_template("home.html").render(
        page=home, url="/", title=home["title"], description=home.get("description", ""), **shared)))

    # Ordinary pages
    for page in pages:
        if page["slug"] == "index":
            continue
        written.append(write(page["url"], env.get_template(page.get("template", "page.html")).render(
            page=page, url=page["url"], title=page["title"],
            description=page.get("description", ""), **shared)))

    # Ontology documentation
    for onto in ontologies:
        written.append(write(onto["url"], env.get_template("ontology.html").render(
            onto=onto, page=onto, url=onto["url"], title=onto["title"],
            description=onto["summary"], **shared)))

    # Blog
    written.append(write("/blog/", env.get_template("blog_index.html").render(
        url="/blog/", title="Notes", description=config["blog_description"], **shared)))
    for i, post in enumerate(posts):
        written.append(write(post["url"], env.get_template("post.html").render(
            post=post, page=post, url=post["url"], title=post["title"],
            description=post["summary"],
            newer=posts[i - 1] if i else None,
            older=posts[i + 1] if i + 1 < len(posts) else None,
            **shared)))
    for tag, tagged in shared["tags"].items():
        url = f"/blog/tag/{slugify(tag)}/"
        written.append(write(url, env.get_template("tag.html").render(
            tag=tag, tagged=tagged, url=url, title=f"Notes tagged “{tag}”",
            description=f"Posts tagged {tag}.", **shared)))

    # Machine-facing documents
    written.append(write("/feed.xml", env.get_template("atom.xml").render(
        url="/feed.xml", title="feed", description="", **shared)))
    written.append(write("/sitemap.xml", env.get_template("sitemap.xml").render(
        urls=sorted({"/", "/blog/", *[p["url"] for p in pages if p["slug"] != "index"],
                     *[o["url"] for o in ontologies], *[p["url"] for p in posts]}),
        url="/sitemap.xml", title="sitemap", description="", **shared)))
    written.append(write("/robots.txt", env.get_template("robots.txt").render(**shared)))
    written.append(write("/404.html", env.get_template("404.html").render(
        url="/404.html", title="Not found", description="", **shared)))

    static_count = copy_tree(STATIC, OUT)
    ttl_count = copy_tree(DIST, OUT)

    return {
        "pages": len(written),
        "posts": len(posts),
        "ontologies": len(ontologies),
        "static": static_count,
        "rdf": ttl_count,
        "written": written,
        "config": config,
        "ontology_list": ontologies,
        "post_list": posts,
    }


# ---------------------------------------------------------------------------
# Checks
# ---------------------------------------------------------------------------

HREF_RE = re.compile(r'(?:href|src)="(/[^"#]*)(#[^"]*)?"')


def check(result: dict[str, Any]) -> int:
    """Verify that every internal link resolves and every ontology is staged."""
    problems: list[str] = []
    for path in sorted(OUT.rglob("*.html")):
        text = path.read_text(encoding="utf-8")
        for match in HREF_RE.finditer(text):
            target = match.group(1)
            candidate = OUT / target.lstrip("/")
            if target.endswith("/"):
                candidate = candidate / "index.html"
            if not candidate.exists():
                problems.append(f"{path.relative_to(OUT)}: dead link {target}")

    for onto in result["ontology_list"]:
        for entry in onto["files"]:
            if not entry.get("exists"):
                problems.append(f"{onto['slug']}: {entry['file']} is not staged")
        if onto["rdf"] and not onto["rdf"]["version"]:
            problems.append(f"{onto['slug']}: no owl:versionInfo in the Turtle")

    leaked = [p.relative_to(OUT) for p in OUT.rglob("*.ttl")
              if re.search(r"https?://[^ <>]*example\.org", p.read_text(encoding="utf-8"))]
    problems.extend(f"{p}: an example.org IRI reached the output" for p in leaked)

    for problem in problems:
        print(f"  FAIL {problem}", file=sys.stderr)
    if problems:
        print(f"\n{len(problems)} problem(s) found.", file=sys.stderr)
        return 1
    print("  all internal links resolve; every ontology staged; no example.org IRIs")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--check", action="store_true", help="verify links and staging after building")
    parser.add_argument("--serve", action="store_true", help="serve site/ on localhost after building")
    parser.add_argument("--port", type=int, default=8000)
    args = parser.parse_args()

    if OUT.exists():
        shutil.rmtree(OUT)
    result = build()
    print(f"built {result['pages']} documents "
          f"({result['ontologies']} ontologies, {result['posts']} posts), "
          f"{result['static']} static files, {result['rdf']} RDF files -> site/")

    status = check(result) if args.check else 0

    if args.serve and status == 0:
        import functools
        import http.server
        import socketserver
        handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(OUT))
        with socketserver.TCPServer(("", args.port), handler) as httpd:
            print(f"serving http://localhost:{args.port}/  (Ctrl-C to stop)")
            try:
                httpd.serve_forever()
            except KeyboardInterrupt:
                print()
    return status


if __name__ == "__main__":
    raise SystemExit(main())
