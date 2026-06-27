#!/usr/bin/env bash
# Migrate the Record Harm Ontology from the placeholder example.org namespace to
# the permanent epistemic-ontology.net base, and stage the serializations into
# the website for hosting.
#
# This is the concrete replacement of the "dangling" example.org IRI:
#   http://example.org/record-harm-ontology#  ->  https://www.epistemic-ontology.net/record-harm#
#
# Re-runnable. Pass the source repo path as $1 (defaults to a sibling checkout).
set -euo pipefail

SRC="${1:-$HOME/claude/record-harm-ontology}"
DEST="$(cd "$(dirname "$0")" && pwd)/site/record-harm"

OLD='http://example.org/record-harm-ontology#'
NEW='https://www.epistemic-ontology.net/record-harm#'

declare -A FILES=(
  ["ontology/record-harm-ontology.ttl"]="record-harm-ontology.ttl"
  ["shapes/record-harm-shapes.ttl"]="record-harm-shapes.ttl"
  ["examples/example-harm-events.ttl"]="example-harm-events.ttl"
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
  sed "s|${OLD}|${NEW}|g" "$src" > "$out"
  echo "migrated  $src_rel  ->  site/record-harm/${FILES[$src_rel]}"
done

# Sanity: no example.org references should remain in the hosted copies.
if grep -rl "example.org" "$DEST" >/dev/null 2>&1; then
  echo "error: example.org still present in migrated output" >&2
  exit 1
fi
echo "done — hosted namespace is now ${NEW}"
