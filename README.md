# epistemic-ontology.net

Source for **https://epistemic-ontology.net/** — a home for formal,
dereferenceable ontologies. It publishes the **Record Ontology** (`/record`), its
**Arithmetic Companion** (`/arith`), and the **Record Harm Ontology**
(`/record-harm`), and is laid out to take further vocabularies under their own
slugs.

The site is also the permanent replacement for the placeholder `example.org`
namespace the Record Harm Ontology was drafted under:

```
http://example.org/record-harm-ontology#   →   https://www.epistemic-ontology.net/record-harm#
```

## How it is put together

Content is Markdown, layout is Jinja, and **anything that can be read off the
RDF is read off the RDF**. Version strings, ontology titles, licences, imports
and term counts are extracted from the staged Turtle with rdflib at build time,
so the site cannot advertise a version it is not serving. (It used to: the pages
claimed Record Ontology v0.5.0 for weeks after the ontology had moved to v0.6.0.
That class of drift is now impossible.)

```
eon/
├── build.py                  # the generator: content + templates -> site/
├── Makefile                  # build / serve / stage / check / deploy
├── requirements.txt          # Jinja2, markdown-it-py, PyYAML, rdflib
│
├── content/                  # ← everything you edit day to day
│   ├── site.yaml             #   global config: title, nav, base URL, author
│   ├── pages/                #   index, using, about
│   ├── ontologies/           #   one file per published vocabulary
│   └── blog/                 #   YYYY-MM-DD-slug.md, one per post
│
├── templates/                # base layout + one template per page kind
├── static/                   # style.css, logo, favicons — copied verbatim
├── ontology-dist/            # staged serializations (the RDF that is served)
│   ├── record/{record-ontology.ttl,examples/*.ttl}
│   ├── arith/arith.ttl
│   └── record-harm/*.ttl
│
├── site/                     # BUILD OUTPUT — committed, deployed, disposable
├── nginx/epistemic-ontology.net.conf
├── stage-record.sh           # record + arith + examples: copy (born permanent)
├── migrate.sh                # record-harm: rewrite example.org, then copy
└── make-icons.sh             # regenerate favicons from logo.png
```

`site/` is committed so the exact served bytes are reviewable in git history and
deployable without a Python environment. It is regenerated from scratch on every
build; never edit it. `make fresh` fails if it is stale.

## Everyday tasks

```bash
make install     # pip install -r requirements.txt (once)
make             # build into site/
make serve       # build + preview on http://localhost:8000
make check       # build + verify links, staging, namespaces
make check-server  # read-only health check of the LIVE server
```

### Write a post

Create `content/blog/YYYY-MM-DD-slug.md`:

```markdown
---
title: A title
date: 2026-07-30
seq: 1                 # optional: orders posts published on the same day
tags: [design, warrant]
summary: >-
  One or two sentences. Used on the index, in the feed, and as the
  meta description.
reading:               # optional sidebar links
  - { title: "Record Ontology", url: "/record/" }
---

Body in Markdown. Fenced code blocks are syntax-highlighted at build time for
turtle, bash, python and bibtex — no JavaScript is shipped for it.
```

The URL is the filename minus the date prefix. Headings get stable ids, a table
of contents is collected automatically, and the Atom feed, sitemap and tag pages
regenerate themselves. Set `draft: true` to keep a post out of the build.

### Refresh the hosted ontologies

```bash
make stage                                   # both, from the default paths
./stage-record.sh ~/path/to/record-ontology  # or individually
./migrate.sh      ~/path/to/record-harm-ontology
```

- **`stage-record.sh`** only *copies*: the Record Ontology and the Arithmetic
  Companion were born at their permanent namespaces, so their hosted copies are
  byte-identical to source. It asserts the permanent namespace is present.
- **`migrate.sh`** *rewrites* `example.org` → `epistemic-ontology.net` for
  record-harm and fails if any placeholder IRI survives, so the hosted copy can
  never drift back.

Both refuse to finish if an `example.org` IRI reaches the output, and so does
`build.py --check`.

> Adopting `https://www.epistemic-ontology.net/record-harm#` as the canonical
> base *in the record-harm source repository* is that ontology's own v3.0
> (breaking) release decision. Until then the hosted copy is a migrated one.

### Add an ontology

1. Stage its serializations into `ontology-dist/<slug>/` (extend
   `stage-record.sh`, or add a script).
2. Add `content/ontologies/<slug>.md` — copy `arith.md`, it is the shortest.
   Front matter carries the namespace, prefix, files and badges; the body is
   documentation. Version and term counts come from the Turtle.
3. Add a `map` and a `location = /<slug>` pair to the nginx config so the bare
   IRI content-negotiates.

The landing page, sitemap, and 404 page pick it up with no further edits.

## Dereferenceable IRIs

All vocabularies here use **hash** namespaces, so every term shares one document
and the fragment is resolved client-side. The bare IRI negotiates on `Accept`
and answers `303`:

```bash
curl -L -H "Accept: text/html"   https://epistemic-ontology.net/record   # documentation
curl -L -H "Accept: text/turtle" https://epistemic-ontology.net/record   # RDF
```

Worked examples are dereferenceable too. Each declares its own IRI
systematically, as `…/record/examples/<name>#`, and nginx maps the extensionless
form to the Turtle. `examples/minimal/` is deliberately not hosted: all ten of
those files share one namespace, so no single file can own that IRI.

## Deploy

Deployment settings live in `deploy.env`, which is **gitignored** — this is a
public repository and infrastructure specifics do not belong in it:

```bash
cp deploy.env.example deploy.env && $EDITOR deploy.env
```

Two ways to ship, and the first is preferred:

```bash
make release     # commit-and-push, then the SERVER pulls and installs itself
make deploy      # push from here: rsync site/, fix ownership, reload nginx
```

`make release` is better because the server decides what it runs, it works
without this workstation, and `server/install.sh` **tests the nginx config
before keeping it** — if `nginx -t` fails it restores the previous config and
aborts without touching content. That is the exact failure that took the site
down on 2026-07-31: a config that could not load, installed anyway, leaving
nginx unable to start at all.

### On the server

`server/install.sh` runs on the box. Because `site/` is committed, the server
needs only `git` and `rsync` — no Python, no build step, no toolchain to keep
current. What is in git is exactly what is served.

```bash
./server/install.sh              # pull the default branch and install
./server/install.sh --dry-run    # show what would change, touch nothing
./server/install.sh --ref v1.2   # install a specific tag, branch or commit
```

It refuses to proceed if another `*.conf` sits in `conf.d` (nginx loads those
too, and a second `default_server` is fatal), starts nginx rather than reloading
if the service is down, and finishes by verifying that the IRIs negotiate with
CORS and charset intact.

First run, before the checkout exists:

```bash
sudo dnf install -y git rsync
sudo git clone https://github.com/commuted/eon.git /opt/eon
sudo chown -R "$(id -un):$(id -gn)" /opt/eon
/opt/eon/server/install.sh
```

First-time server setup:

```bash
# 1. Install the server block
sudo cp nginx/epistemic-ontology.net.conf /etc/nginx/sites-available/epistemic-ontology.net
sudo ln -s /etc/nginx/sites-available/epistemic-ontology.net /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

# 2. TLS — the cert MUST cover every name in server_name, or .org / www
#    visitors get a certificate-mismatch error.
sudo certbot --nginx \
  -d epistemic-ontology.net -d www.epistemic-ontology.net \
  -d epistemic-ontology.org -d www.epistemic-ontology.org
```

DNS: point `A`/`AAAA` records for all four names at the server. The canonical
host is the apex `https://epistemic-ontology.net`; HTTP (and the bare IP) and the
other three names all `301`-redirect to it. The namespace IRIs minted at
`www.epistemic-ontology.net` therefore resolve via one permanent `301` to the
apex, then the `303` content negotiation.

### Post-deploy check

```bash
curl -sI -H "Accept: text/turtle" https://epistemic-ontology.net/record   # 303 → .ttl
curl -sI https://epistemic-ontology.net/record/examples/saccheri          # 303 → .ttl
curl -s  https://epistemic-ontology.net/feed.xml | head -5                # Atom
```

## What `make check-server` checks

Read-only, safe to run at any time, and safe to run when you already suspect
something is wrong. It exists because of a real outage: the config was once
copied to **both** `conf.d/default.conf` and `conf.d/epistemic-ontology.net.conf`.
`nginx.conf` includes `conf.d/*.conf`, so both declared `default_server`, nginx
refused to start, and the site stayed down. `nginx -t` had been failing the whole
time — nothing was asking it.

- nginx is **running**, **enabled at boot**, and `nginx -t` passes
- **exactly one** site config is loaded, and nothing else sits in `conf.d`
- the live config is **byte-identical** to `nginx/` in this repo
- the served tree matches `site/`, file for file and size for size
- the namespace IRIs still `303` to Turtle, with `Access-Control-Allow-Origin`
  and `Vary: Accept` on the redirect, `text/turtle; charset=utf-8` on the RDF,
  and the example IRIs and compatibility redirects intact

It exits non-zero on any failure, so it can gate a cron job. `make deploy` runs
it automatically as its last step.

## What the build checks

`build.py --check` (run by `make check` and before every deploy) fails on:

- a dead internal link in any generated page;
- an ontology whose front matter names a file that is not staged;
- an ontology whose Turtle carries no `owl:versionInfo`;
- any `example.org` IRI that reached the output.

## Assets

`style.css` is emitted twice: once under its own content hash
(`style.<sha>.css`), which is what every page links to, and once under the plain
name so external references keep working. The hash changes only when the CSS
changes, which lets nginx serve the fingerprinted copy with
`max-age=31536000, immutable` — it is never revalidated, and a stale stylesheet
against fresh markup becomes impossible.

Images and favicons are deliberately *not* fingerprinted: `favicon.ico` is
fetched by browsers at a fixed path, and `logo.png` is the Open Graph image,
where a stable URL matters more to social-media caches than instant updates.
