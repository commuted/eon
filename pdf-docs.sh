#!/usr/bin/env bash
# Generate the SITE's PDF copy of ontology documentation that cannot simply be
# copied from the source repository.
#
# WHY THIS EXISTS
#   migrate.sh rewrites the drafting placeholder namespace to the permanent base
#   in every text file it stages. A PDF cannot be rewritten that way -- its text
#   stream is compressed -- so a PDF built upstream freezes whichever namespace
#   the author's machine had. record-harm-ontology/docs/README.pdf does exactly
#   that: three `PREFIX ex: <http://example.org/...>` examples, which would hand
#   a visitor SPARQL that returns nothing against the data served here. That
#   file is not defective; in its own repository it is correct. It is simply not
#   publishable.
#
#   So the site's copy is GENERATED: rewrite the Markdown first, then render and
#   print. The upstream PDF is left alone.
#
# HOW
#   build.py's own renderer and the site's own stylesheet, so the result reads
#   like epistemic-ontology.net rather than like a converter's defaults; then
#   Chromium print-to-PDF, which is the engine that produced the upstream PDFs.
#   pdftotext then proves the placeholder is gone -- a plain `grep` on a PDF
#   finds nothing even when the string is there, so a text guard would give a
#   false all-clear.
#
# IDEMPOTENCE
#   Chromium stamps the wall-clock time into every PDF, so two runs over
#   identical input differ in bytes. site/ is committed, so regenerating on
#   every `make stage` would dirty the tree forever and `make fresh` would
#   demand a commit of a byte-different file with identical content. This script
#   therefore hashes its inputs and skips the work when they have not changed.
#   The hash lives in a dotfile beside the PDF: committed, and not published,
#   because build.py's copy_tree skips names beginning with a dot.
#
#   The provenance line printed into the PDF deliberately does NOT name the
#   source commit. It would be better provenance, but it would also change the
#   output on every upstream commit, so the hash would have to include it and
#   the PDF would be regenerated when nothing a reader sees had changed.
#
# Usage:
#     ./pdf-docs.sh [path/to/record-harm-ontology]
set -uo pipefail

# Bump when the rendering changes (stylesheet wrapper, flags, provenance text),
# so existing PDFs are regenerated rather than kept on a stale hash.
PIPELINE_VERSION=1

SRC="${1:-$HOME/claude/record-harm-ontology}"
HERE="$(cd "$(dirname "$0")" && pwd)"
DEST="$HERE/ontology-dist/record-harm"
CSS="$HERE/static/style.css"

OLD='http://example.org/record-harm-ontology#'
NEW='https://www.epistemic-ontology.net/record-harm#'

# src-relative-path : output-name : document title
DOCS=(
  "README.md:README.pdf:Record Harm Ontology — README"
)

[ -d "$SRC" ] || { echo "error: source repo not found at $SRC" >&2; exit 2; }
[ -f "$CSS" ] || { echo "error: stylesheet not found at $CSS" >&2; exit 2; }

CHROME=""
for c in google-chrome chromium chromium-browser; do
  command -v "$c" >/dev/null && { CHROME="$c"; break; }
done
[ -n "$CHROME" ] || {
  echo "error: no Chromium/Chrome found; needed to print the PDF" >&2
  echo "       (the upstream PDFs were made with it: Producer Skia/PDF)" >&2
  exit 2
}
command -v sha256sum >/dev/null || { echo "error: sha256sum not found" >&2; exit 2; }

mkdir -p "$DEST"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

for spec in "${DOCS[@]}"; do
  rel="${spec%%:*}"; rest="${spec#*:}"
  out_name="${rest%%:*}"; title="${rest#*:}"
  src="$SRC/$rel"
  out="$DEST/$out_name"
  sums="$DEST/.$out_name.sha256"

  if [ ! -f "$src" ]; then
    echo "warn: missing $rel -- skipping" >&2
    continue
  fi

  # The rewritten Markdown is both what gets rendered and what gets hashed.
  sed "s|${OLD}|${NEW}|g" "$src" > "$TMP/doc.md"
  want="$(cat "$TMP/doc.md" "$CSS" <(echo "$PIPELINE_VERSION") | sha256sum | cut -d' ' -f1)"

  if [ -f "$out" ] && [ -f "$sums" ] && [ "$(cat "$sums")" = "$want" ]; then
    echo "unchanged $rel  (PDF current; not reprinted)"
    continue
  fi

  python3 - "$TMP/doc.md" "$CSS" "$TMP/doc.html" "$title" "$rel" "$NEW" <<'PY'
import sys, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
sys.path.insert(0, "/home/ron/claude/eon")
import build

md, css, out, title, rel, ns = sys.argv[1:7]
rendered = build.render_markdown(pathlib.Path(md).read_text(encoding="utf-8"))
pathlib.Path(out).write_text(
    "<!doctype html><html lang=en><meta charset=utf-8>"
    f"<title>{title}</title><style>{pathlib.Path(css).read_text(encoding='utf-8')}\n"
    "@page { margin: 18mm; }\n"
    "body { max-width: none; margin: 0; }\n"
    ".pdf-provenance { font-size: .8rem; opacity: .75; margin: 0 0 1.5rem;"
    " padding-bottom: .75rem; border-bottom: 1px solid currentColor; }\n"
    "</style>"
    f"<main class=prose><p class=pdf-provenance>Generated for "
    "epistemic-ontology.net from <code>" + rel + "</code> in the Record Harm "
    "Ontology repository. Term IRIs are the permanent ones under <code>"
    + ns + "</code>; the repository itself still drafts under a placeholder "
    "base, so queries copied from the repository will differ.</p>"
    f"{rendered.html}</main></html>",
    encoding="utf-8")
PY
  [ -f "$TMP/doc.html" ] || { echo "error: rendering $rel failed" >&2; exit 1; }

  if ! "$CHROME" --headless --disable-gpu --no-sandbox --no-pdf-header-footer \
        --print-to-pdf="$TMP/doc.pdf" "$TMP/doc.html" >/dev/null 2>&1; then
    echo "error: $CHROME failed to print $rel" >&2
    exit 1
  fi
  [ -s "$TMP/doc.pdf" ] || { echo "error: $CHROME produced no PDF for $rel" >&2; exit 1; }

  # The whole point of generating rather than copying. Checked with pdftotext
  # because grep cannot see into a compressed text stream.
  if command -v pdftotext >/dev/null; then
    if pdftotext "$TMP/doc.pdf" - 2>/dev/null | grep -qE "https?://[^ <>]*example[.]org"; then
      echo "error: a placeholder IRI survived into the generated $out_name" >&2
      exit 1
    fi
    verdict="pdftotext: clean"
  else
    verdict="UNVERIFIED (install poppler-utils for pdftotext)"
  fi

  mv "$TMP/doc.pdf" "$out"
  printf '%s' "$want" > "$sums"
  pages="$(pdfinfo "$out" 2>/dev/null | awk '/^Pages/{print $2}')"
  printf 'generated %-14s -> ontology-dist/record-harm/%s  (%s pages, %s)\n' \
    "$rel" "$out_name" "${pages:-?}" "$verdict"
done
