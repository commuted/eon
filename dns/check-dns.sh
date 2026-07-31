#!/usr/bin/env bash
# Report the mail-authentication records published for a domain, and flag what
# is missing or malformed. Read-only: it only makes DNS queries.
#
# The point is that "no record" and "correct record" look identical from a
# browser -- nothing about the website tells you the domain is spoofable. This
# asks the questions a receiving mail server would ask.
#
# Usage:
#     ./dns/check-dns.sh                      # every domain listed below
#     ./dns/check-dns.sh example.com          # one domain
#     ./dns/check-dns.sh example.com nomail   # expect the lock-down set
set -uo pipefail

DOMAINS_DEFAULT=(epistemic-ontology.net epistemic-ontology.org rhymeswith.net)
# Domains that should carry the "no mail, ever" set rather than a live config.
NOMAIL=(epistemic-ontology.org)

command -v dig >/dev/null || { echo "error: dig not found (install bind-utils / dnsutils)" >&2; exit 2; }

fails=0
if [ -t 1 ]; then G=$'\033[32m'; R=$'\033[31m'; Y=$'\033[33m'; B=$'\033[1m'; Z=$'\033[0m'
else G=''; R=''; Y=''; B=''; Z=''; fi
ok()   { printf '  %sok%s    %s\n' "$G" "$Z" "$1"; }
bad()  { printf '  %sFAIL%s  %s\n' "$R" "$Z" "$1"; fails=$((fails + 1)); }
warn() { printf '  %swarn%s  %s\n' "$Y" "$Z" "$1"; }
note() { printf '        %s\n' "$1"; }

is_nomail() {
  local d="$1"
  for n in "${NOMAIL[@]}"; do [ "$d" = "$n" ] && return 0; done
  return 1
}

check_domain() {
  local d="$1" mode="$2"
  printf '\n%s%s%s  (%s)\n' "$B" "$d" "$Z" "$mode"

  # --- MX ------------------------------------------------------------------
  local mx; mx=$(dig +short MX "$d" | sort)
  if [ -z "$mx" ]; then
    if [ "$mode" = nomail ]; then
      bad "no MX at all — add a null MX (\`0 .\`) to declare the domain accepts no mail"
      note "without it, senders queue and retry for days instead of failing fast"
    else
      bad "no MX — this domain cannot receive mail"
    fi
  elif [ "$mx" = "0 ." ]; then
    if [ "$mode" = nomail ]; then ok "null MX (\`0 .\`) — accepts no mail, by declaration"
    else bad "null MX, but this domain is supposed to receive mail"; fi
  else
    if [ "$mode" = nomail ]; then
      bad "MX present on a domain that should receive nothing:"; note "$mx"
    else
      ok "MX:"; while read -r l; do note "$l"; done <<<"$mx"
    fi
  fi

  # --- SPF -----------------------------------------------------------------
  local spf n_spf
  spf=$(dig +short TXT "$d" | tr -d '"' | grep -i '^v=spf1' || true)
  n_spf=$(printf '%s' "$spf" | grep -c . || true)
  if [ -z "$spf" ]; then
    bad "no SPF record — nothing states who may send as this domain"
  elif [ "$n_spf" -gt 1 ]; then
    bad "$n_spf SPF records — more than one is a permerror, and BOTH are ignored:"
    while read -r l; do note "$l"; done <<<"$spf"
  else
    case "$spf" in
      *" -all"|*"-all") ok "SPF: $spf" ;;
      *"~all") if [ "$mode" = nomail ]; then bad "SPF ends ~all (softfail); a no-mail domain wants -all: $spf"
               else ok "SPF: $spf"; note "~all is softfail; -all is stricter once you trust the config"; fi ;;
      *"?all"|*"+all") bad "SPF neutral or permissive — it authorises everyone: $spf" ;;
      *) warn "SPF has no explicit all mechanism: $spf" ;;
    esac
  fi

  # --- DMARC ---------------------------------------------------------------
  # A DMARC record is read ONLY at _dmarc.<domain>. Put it on the apex and it is
  # inert: no receiver ever looks there, and nothing reports the mistake. This
  # has actually happened on one of these domains, so it is checked explicitly.
  local dmarc apex_dmarc
  dmarc=$(dig +short TXT "_dmarc.$d" | tr -d '"' | grep -i '^v=DMARC1' || true)
  apex_dmarc=$(dig +short TXT "$d" | tr -d '"' | grep -i '^v=DMARC1' || true)
  if [ -n "$apex_dmarc" ]; then
    bad "a DMARC record sits on the APEX, where nothing reads it:"
    note "$apex_dmarc"
    note "move it to _dmarc.$d — on the apex it is decoration, not policy"
  fi
  if [ -z "$dmarc" ]; then
    bad "no DMARC record at _dmarc.$d — receivers have no instruction for failures"
  else
    local pol; pol=$(sed -n 's/.*[;[:space:]]p=\([a-z]*\).*/\1/p' <<<"$dmarc")
    case "$pol" in
      reject)     ok "DMARC p=reject" ;;
      quarantine) ok "DMARC p=quarantine"; note "tighten to p=reject once reports look clean" ;;
      none)       warn "DMARC p=none — monitoring only, nothing is rejected" ;;
      *)          bad "DMARC present but no readable policy: $dmarc" ;;
    esac
    [ "$mode" = nomail ] && [ "$pol" != reject ] && \
      bad "a domain that sends no mail should be p=reject"
    grep -qi 'sp=' <<<"$dmarc" || note "no sp= — subdomains inherit p, which is usually what you want"
    grep -qi 'rua=' <<<"$dmarc" || note "no rua= — you will receive no aggregate reports"
  fi

  # --- DKIM ----------------------------------------------------------------
  local wild; wild=$(dig +short TXT "*._domainkey.$d" | tr -d '"' || true)
  if [ "$mode" = nomail ]; then
    if grep -qi 'p=[[:space:]]*$\|p=;' <<<"${wild:-}" || [ "${wild:-}" = "v=DKIM1; p=" ]; then
      ok "wildcard DKIM revoked (\`v=DKIM1; p=\`)"
    else
      warn "no wildcard DKIM revocation — optional, but it voids any selector a spoofer invents"
    fi
  else
    local found=0
    for s in protonmail protonmail2 protonmail3 default google selector1 selector2; do
      local r; r=$(dig +short CNAME "$s._domainkey.$d"; dig +short TXT "$s._domainkey.$d")
      [ -n "$r" ] && { ok "DKIM selector '$s' present"; found=$((found+1)); }
    done
    [ "$found" = 0 ] && bad "no DKIM found at any common selector — mail will be DKIM-unsigned"
  fi
}

main() {
  local domains=()
  if [ $# -ge 1 ]; then domains=("$1"); else domains=("${DOMAINS_DEFAULT[@]}"); fi
  local forced="${2:-}"
  for d in "${domains[@]}"; do
    local mode="live"
    if [ -n "$forced" ]; then mode="$forced"
    elif is_nomail "$d"; then mode="nomail"; fi
    check_domain "$d" "$mode"
  done
  printf '\n'
  if [ "$fails" -eq 0 ]; then echo "mail records look correct."
  else echo "$fails problem(s). See dns/README.md for the records to publish."; fi
  exit $(( fails > 0 ))
}

main "$@"
