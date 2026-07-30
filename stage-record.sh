#!/usr/bin/env bash
# Stage the Record Ontology, the Arithmetic Companion and the worked examples
# into ontology-dist/ for hosting.
#
# Unlike record-harm (see migrate.sh), these were BORN at permanent namespaces
# under https://www.epistemic-ontology.net/ -- so there is nothing to rewrite;
# this copies the files and asserts the namespaces are already permanent (and
# that no example.org placeholder ever crept in).
#
# Every top-level example declares its own IRI systematically, as
#   https://www.epistemic-ontology.net/record/examples/<basename>#
# so staging them under ontology-dist/record/examples/<basename>.ttl makes each
# of those namespaces dereferenceable too (see the nginx config). The
# examples/minimal/ set is deliberately NOT staged: all ten share one namespace
# (.../record/examples/minimal#), so no single file can own that IRI.
#
# Re-runnable. Pass the source repo path as $1 (defaults to a sibling checkout).
set -euo pipefail

SRC="${1:-$HOME/claude/record-ontology}"
BASE="$(cd "$(dirname "$0")" && pwd)/ontology-dist"

NS_RECORD='https://www.epistemic-ontology.net/record#'
NS_ARITH='https://www.epistemic-ontology.net/arith#'

if [ ! -d "$SRC" ]; then
  echo "error: source repo not found at $SRC (pass it as the first argument)" >&2
  exit 1
fi

stage() {  # stage <src-relative-path> <dest-relative-path>
  local src="$SRC/$1" out="$BASE/$2"
  if [ ! -f "$src" ]; then
    echo "warn: missing $1 — skipping" >&2
    return
  fi
  mkdir -p "$(dirname "$out")"
  cp "$src" "$out"
  printf 'staged    %-40s -> ontology-dist/%s\n' "$1" "$2"
}

# --- the ontologies --------------------------------------------------------
stage ontology/record-ontology.ttl record/record-ontology.ttl
stage ontology/arith.ttl           arith/arith.ttl

# --- the worked examples ---------------------------------------------------
# Kept in the order the documentation introduces them.
for name in \
  cogito \
  historical-narrative \
  neptune-discovery \
  bohr-atom \
  triangle-described \
  saccheri \
  kepler-mars \
  cuban-missile \
  tonkin-consent \
  arith-properties \
  trig-basics \
  orbital-mechanics
do
  stage "examples/${name}.ttl" "record/examples/${name}.ttl"
done

# --- sanity ----------------------------------------------------------------
if ! grep -q "$NS_RECORD" "$BASE/record/record-ontology.ttl"; then
  echo "error: permanent namespace $NS_RECORD not found in staged ontology" >&2
  exit 1
fi
if [ -f "$BASE/arith/arith.ttl" ] && ! grep -q "$NS_ARITH" "$BASE/arith/arith.ttl"; then
  echo "error: permanent namespace $NS_ARITH not found in staged companion" >&2
  exit 1
fi
# Match the URL form only -- the ontology header mentions "example.org" in a
# comment explaining it was NOT drafted under that placeholder.
if grep -rInE "https?://[^ <>]*example\.org" "$BASE/record" "$BASE/arith" >/dev/null 2>&1; then
  echo "error: an example.org IRI is present in staged output" >&2
  exit 1
fi

echo "done — hosted namespaces are ${NS_RECORD} and ${NS_ARITH}"
