#!/usr/bin/env bash
# Stage the Record Ontology serializations into the website for hosting.
#
# Unlike record-harm (see migrate.sh), the Record Ontology was BORN at the
# permanent namespace https://www.epistemic-ontology.net/record# -- so there is
# nothing to rewrite; this just copies the files and asserts the namespace is
# already permanent (and that no example.org placeholder ever crept in).
#
# Re-runnable. Pass the source repo path as $1 (defaults to a sibling checkout).
set -euo pipefail

SRC="${1:-$HOME/claude/record-ontology}"
DEST="$(cd "$(dirname "$0")" && pwd)/site/record"

NS='https://www.epistemic-ontology.net/record#'

declare -A FILES=(
  ["ontology/record-ontology.ttl"]="record-ontology.ttl"
  ["examples/historical-narrative.ttl"]="historical-narrative.ttl"
  ["examples/cogito.ttl"]="cogito.ttl"
)

if [ ! -d "$SRC" ]; then
  echo "error: source repo not found at $SRC (pass it as the first argument)" >&2
  exit 1
fi

mkdir -p "$DEST"
for src_rel in "${!FILES[@]}"; do
  src="$SRC/$src_rel"
  out="$DEST/${FILES[$src_rel]}"
  if [ ! -f "$src" ]; then
    echo "warn: missing $src — skipping" >&2
    continue
  fi
  cp "$src" "$out"
  echo "staged    $src_rel  ->  site/record/${FILES[$src_rel]}"
done

# Sanity: the permanent namespace must be present, and no example.org IRI.
# (Match the URL form only -- the ontology header mentions "example.org" in a
# comment explaining it was NOT drafted under that placeholder.)
if ! grep -q "$NS" "$DEST/record-ontology.ttl"; then
  echo "error: permanent namespace $NS not found in staged ontology" >&2
  exit 1
fi
if grep -rInE "https?://[^ <>]*example\.org" "$DEST" >/dev/null 2>&1; then
  echo "error: an example.org IRI is present in staged output" >&2
  exit 1
fi
echo "done — hosted namespace is ${NS}"
