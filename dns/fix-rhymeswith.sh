#!/usr/bin/env bash
# Fix rhymeswith.net's outbound mail authentication in Route 53.
#
# Two defects, both verified against the zone's authoritative nameserver:
#
#   1. The DMARC record sits on the APEX, where nothing reads it. DMARC is only
#      ever looked up at _dmarc.<domain>; on the apex it is decoration.
#   2. No DKIM records exist. Outbound mail is unsigned, so it passes DMARC on
#      SPF alignment alone -- and fails the moment a message is FORWARDED, since
#      forwarding preserves DKIM and breaks SPF. That is the case DKIM is for,
#      and forwarding is exactly what this domain does.
#
# THE HAZARD THIS SCRIPT EXISTS TO AVOID
# --------------------------------------
# The apex TXT is a SINGLE Route 53 record set holding three strings: the SPF
# record, the Proton verification token, and the stray DMARC string. Removing
# one means rewriting the whole set. Do it by hand and a slip deletes SPF or the
# verification token -- both load-bearing for mail that currently works.
#
# So this script never types those values. It READS the live record set, removes
# only strings beginning v=DMARC1, and writes back exactly what it found
# otherwise. It refuses to proceed if SPF or the verification token would be
# lost.
#
# Requires: aws CLI with route53:ChangeResourceRecordSets on the zone.
#
# Usage:
#   ./dns/fix-rhymeswith.sh --dry-run
#   ./dns/fix-rhymeswith.sh --dkim1 <target> --dkim2 <target> --dkim3 <target>
#
# The three DKIM targets come from Proton: Settings -> All settings -> Domain
# names -> rhymeswith.net -> DKIM. They look like
#   <hash>.domainkey.<token>.domains.proton.ch
set -euo pipefail

DOMAIN="${EON_DOMAIN:-rhymeswith.net}"
DMARC_POLICY="${EON_DMARC:-v=DMARC1; p=none; rua=mailto:postmaster@$DOMAIN}"
DRY=0
D1=""; D2=""; D3=""

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1 ;;
    --dkim1) D1="${2:-}"; shift ;;
    --dkim2) D2="${2:-}"; shift ;;
    --dkim3) D3="${2:-}"; shift ;;
    --domain) DOMAIN="${2:-}"; shift ;;
    -h|--help) sed -n '2,32p' "$0"; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
  shift
done

say() { printf '\n\033[1m%s\033[0m\n' "$*"; }
die() { printf '\n\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }

command -v aws >/dev/null || die "aws CLI not found. pip install awscli, then configure credentials."
command -v jq  >/dev/null || die "jq not found (needed to edit the record set safely)."
aws sts get-caller-identity >/dev/null 2>&1 || die "no working AWS credentials (aws configure)."

# --- locate the zone -------------------------------------------------------
say "zone"
ZONE_ID=$(aws route53 list-hosted-zones-by-name --dns-name "$DOMAIN." \
  --query "HostedZones[?Name=='$DOMAIN.'].Id | [0]" --output text 2>/dev/null || true)
[ -n "$ZONE_ID" ] && [ "$ZONE_ID" != None ] || die "no Route 53 hosted zone for $DOMAIN"
ZONE_ID="${ZONE_ID#/hostedzone/}"
echo "  $DOMAIN -> $ZONE_ID"

# --- read the live apex TXT, do not retype it ------------------------------
say "apex TXT, as published"
APEX=$(aws route53 list-resource-record-sets --hosted-zone-id "$ZONE_ID" \
  --query "ResourceRecordSets[?Name=='$DOMAIN.' && Type=='TXT'] | [0]" --output json)
[ "$APEX" != null ] || die "no apex TXT record set found"
echo "$APEX" | jq -r '.ResourceRecords[].Value' | sed 's/^/  /'

TTL=$(echo "$APEX" | jq -r '.TTL // 300')
KEEP=$(echo "$APEX" | jq '[.ResourceRecords[] | select(.Value | test("v=DMARC1"; "i") | not)]')
DROP=$(echo "$APEX" | jq -r '[.ResourceRecords[] | select(.Value | test("v=DMARC1"; "i")) | .Value] | .[]')

[ -n "$DROP" ] || die "no v=DMARC1 string on the apex — nothing to remove (already fixed?)"

say "what will be removed from the apex"
echo "$DROP" | sed 's/^/  - /'

# Refuse to proceed if the rewrite would lose something load-bearing.
echo "$KEEP" | jq -e 'map(select(.Value | test("v=spf1"; "i"))) | length > 0' >/dev/null \
  || die "SAFETY STOP: the rewrite would not retain an SPF record. Aborting."
echo "$KEEP" | jq -e 'map(select(.Value | test("protonmail-verification"; "i"))) | length > 0' >/dev/null \
  || die "SAFETY STOP: the rewrite would not retain the Proton verification token. Aborting."
say "what will be kept (verified present, copied verbatim)"
echo "$KEEP" | jq -r '.[].Value' | sed 's/^/  + /'

# --- build the change batch ------------------------------------------------
CHANGES=$(jq -n --arg d "$DOMAIN." --arg ttl "$TTL" --argjson keep "$KEEP" \
               --arg dmarc "\"$DMARC_POLICY\"" '
  [ { Action: "UPSERT",
      ResourceRecordSet: { Name: $d, Type: "TXT", TTL: ($ttl|tonumber),
                           ResourceRecords: $keep } },
    { Action: "UPSERT",
      ResourceRecordSet: { Name: ("_dmarc." + $d), Type: "TXT", TTL: 3600,
                           ResourceRecords: [ { Value: $dmarc } ] } } ]')

if [ -n "$D1$D2$D3" ]; then
  [ -n "$D1" ] && [ -n "$D2" ] && [ -n "$D3" ] \
    || die "Proton needs ALL THREE DKIM records. Pass --dkim1, --dkim2 and --dkim3."
  for n in 1 2 3; do
    v=$(eval echo "\$D$n")
    case "$v" in *domains.proton.ch|*domains.proton.ch.) : ;;
      *) die "--dkim$n does not look like a Proton target (expected ...domains.proton.ch): $v" ;;
    esac
  done
  CHANGES=$(jq -n --argjson c "$CHANGES" --arg d "$DOMAIN." \
                 --arg a "$D1" --arg b "$D2" --arg e "$D3" '
    $c + [ {Action:"UPSERT", ResourceRecordSet:{Name:("protonmail._domainkey."+$d),  Type:"CNAME", TTL:3600, ResourceRecords:[{Value:$a}]}},
           {Action:"UPSERT", ResourceRecordSet:{Name:("protonmail2._domainkey."+$d), Type:"CNAME", TTL:3600, ResourceRecords:[{Value:$b}]}},
           {Action:"UPSERT", ResourceRecordSet:{Name:("protonmail3._domainkey."+$d), Type:"CNAME", TTL:3600, ResourceRecords:[{Value:$e}]}} ]')
else
  say "note"
  echo "  No DKIM targets given, so only the DMARC move will be applied."
  echo "  Mail stays unsigned until the three CNAMEs from Proton are added."
fi

say "change batch"
echo "$CHANGES" | jq -r '.[] | "  \(.Action) \(.ResourceRecordSet.Type) \(.ResourceRecordSet.Name)"'

if [ "$DRY" = 1 ]; then
  say "DRY RUN — nothing applied. Full batch:"
  echo "$CHANGES" | jq .
  exit 0
fi

# --- apply -----------------------------------------------------------------
say "applying"
ID=$(aws route53 change-resource-record-sets --hosted-zone-id "$ZONE_ID" \
  --change-batch "$(jq -n --argjson c "$CHANGES" '{Comment:"fix DMARC placement + add DKIM", Changes:$c}')" \
  --query 'ChangeInfo.Id' --output text)
echo "  submitted $ID"
aws route53 wait resource-record-sets-changed --id "$ID" && echo "  propagated to Route 53"

say "verify"
echo "  DNS caches hold the old answers for up to the previous TTL."
echo "  Re-check with:  ./dns/check-dns.sh $DOMAIN"
