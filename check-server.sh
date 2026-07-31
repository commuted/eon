#!/usr/bin/env bash
# Read-only health check of the deployed site. Changes nothing; safe to run any
# time, and safe to run when you suspect something is already wrong.
#
# It exists because of a real failure: the config was once copied to BOTH
# conf.d/default.conf and conf.d/epistemic-ontology.net.conf. Since nginx.conf
# includes conf.d/*.conf, both declared `default_server`, nginx refused to
# start, and the site was down until someone happened to look. `nginx -t` was
# failing the whole time -- nothing was asking it.
#
# Checks, in order of how badly you want to know:
#   1. nginx is running, enabled, and its config passes nginx -t
#   2. exactly one site config is loaded, and no strays sit in conf.d
#   3. the live config is byte-identical to nginx/ in this repo
#   4. the served tree matches site/ in this repo
#   5. the namespace IRIs actually negotiate, with CORS and charset intact
#
# Usage:  ./check-server.sh [user@host] [ssh-key]
set -uo pipefail

HOST="${1:-${DEPLOY_HOST:-}}"
KEY="${2:-${SSH_KEY:-}}"
WEBROOT="${DEPLOY_PATH:-/var/www/html}"
CONF_NAME="epistemic-ontology.net.conf"
REPO="$(cd "$(dirname "$0")" && pwd)"
SSH=(ssh -i "$KEY" -o BatchMode=yes -o ConnectTimeout=10 "$HOST")

fails=0
# Colour only when writing to a terminal, so piping to a file or a log stays clean.
if [ -t 1 ]; then G=$'\033[32m'; R=$'\033[31m'; Y=$'\033[33m'; Z=$'\033[0m'
else G=''; R=''; Y=''; Z=''; fi
ok()   { printf '  %sok%s    %s\n' "$G" "$Z" "$1"; }
bad()  { printf '  %sFAIL%s  %s\n' "$R" "$Z" "$1"; fails=$((fails + 1)); }
warn() { printf '  %swarn%s  %s\n' "$Y" "$Z" "$1"; }
head_() { printf '\n%s\n' "$1"; }

# --- 0. reachable ----------------------------------------------------------
head_ "connection"
if ! "${SSH[@]}" true 2>/dev/null; then
  bad "cannot ssh to $HOST with $KEY"
  echo; echo "1 problem: the server is unreachable, so nothing else could be checked."
  exit 1
fi
ok "ssh to $HOST"

# --- 1..2. nginx state, and what it loads ----------------------------------
remote=$("${SSH[@]}" '
  echo "ACTIVE=$(systemctl is-active nginx 2>/dev/null)"
  echo "ENABLED=$(systemctl is-enabled nginx 2>/dev/null)"
  echo "TEST=$(sudo nginx -t 2>&1 | grep -c "test is successful")"
  echo "TESTERR<<EOT"; sudo nginx -t 2>&1 | grep -E "emerg|\[error\]" ; echo "EOT"
  echo "LOADED<<EOT"; sudo nginx -T 2>/dev/null | sed -n "s/^# configuration file \(.*\):$/\1/p"; echo "EOT"
  echo "CONFD<<EOT"; ls -1 /etc/nginx/conf.d/ 2>/dev/null; echo "EOT"
' 2>/dev/null)

section() { awk -v k="$1" '$0==k"<<EOT"{f=1;next} $0=="EOT"{f=0} f' <<<"$remote"; }

head_ "nginx service"
[[ $(grep -oP '(?<=^ACTIVE=).*' <<<"$remote")  == active  ]] && ok "running"  || bad "not running (systemctl is-active != active)"
[[ $(grep -oP '(?<=^ENABLED=).*' <<<"$remote") == enabled ]] && ok "enabled at boot" || bad "not enabled — it will not come back after a reboot"
if [[ $(grep -oP '(?<=^TEST=).*' <<<"$remote") == 1 ]]; then
  ok "nginx -t passes"
else
  bad "nginx -t FAILS — a reload or reboot will not come up:"
  section TESTERR | sed 's/^/          /'
fi

head_ "loaded configuration"
loaded=$(section LOADED | grep -c "conf.d/")
site_loaded=$(section LOADED | grep -c "conf.d/$CONF_NAME")
[[ $site_loaded == 1 ]] && ok "conf.d/$CONF_NAME is loaded" || bad "conf.d/$CONF_NAME is NOT loaded"
if [[ $loaded -le 1 ]]; then
  ok "no other conf.d file is loaded"
else
  bad "$loaded files loaded from conf.d — duplicate server blocks are likely:"
  section LOADED | grep "conf.d/" | sed 's/^/          /'
fi
strays=$(section CONFD | grep -v "^$CONF_NAME$" || true)
if [[ -z $strays ]]; then
  ok "conf.d holds nothing else"
else
  warn "conf.d also holds (not loaded, but one rename from being loaded):"
  sed 's/^/          /' <<<"$strays"
fi

# --- 3. live config vs repo ------------------------------------------------
head_ "config matches this repo"
if "${SSH[@]}" "sudo cat /etc/nginx/conf.d/$CONF_NAME" 2>/dev/null \
   | diff -q - "$REPO/nginx/$CONF_NAME" >/dev/null; then
  ok "live config is byte-identical to nginx/$CONF_NAME"
else
  bad "live config DIFFERS from nginx/$CONF_NAME:"
  "${SSH[@]}" "sudo cat /etc/nginx/conf.d/$CONF_NAME" 2>/dev/null \
    | diff -u - "$REPO/nginx/$CONF_NAME" | head -40 | sed 's/^/          /'
fi

# --- 4. served tree vs built tree ------------------------------------------
head_ "content matches site/"
if [[ -d $REPO/site ]]; then
  # LC_ALL=C on both sides: locale collation orders '-' and '/' differently, so
  # an en_US sort here against a C sort there makes identical trees look like
  # they differ (record-harm/... vs record/...).
  local_manifest=$(cd "$REPO/site" && find . -type f -printf '%P %s\n' | LC_ALL=C sort)
  remote_manifest=$("${SSH[@]}" "cd $WEBROOT && find . -type f -printf '%P %s\n' | LC_ALL=C sort" 2>/dev/null)
  if [[ $local_manifest == "$remote_manifest" ]]; then
    ok "$(wc -l <<<"$local_manifest") files, all present at the same size"
  else
    bad "served tree differs from site/ (name or size):"
    diff <(echo "$local_manifest") <(echo "$remote_manifest") \
      | grep -E '^[<>]' | head -20 | sed 's/^</          only local: /; s/^>/          only live:  /'
    echo "          run: make deploy"
  fi
else
  warn "site/ is not built locally — skipping (run: make build)"
fi

# --- 5. behaviour, probed on the server ------------------------------------
head_ "dereferencing"
probe=$("${SSH[@]}" '
  R="--resolve epistemic-ontology.net:443:127.0.0.1"
  B="https://epistemic-ontology.net"
  for p in / /blog/ /record/ /arith/ /record-harm/ /using/ /about/ /feed.xml /sitemap.xml; do
    echo "CODE $p $(curl -s $R -o /dev/null -w "%{http_code}" $B$p)"
  done
  for p in /record /record-harm /arith; do
    echo "NEG $p $(curl -sI $R -H "Accept: text/turtle" $B$p | tr -d "\r" | awk "/^HTTP/{c=\$2} /^[Ll]ocation:/{l=\$2} END{print c\" \"l}")"
  done
  echo "CORS $(curl -sI $R -H "Accept: text/turtle" -H "Origin: https://example.com" $B/record \
          | tr -d "\r" | grep -ci "access-control-allow-origin")"
  echo "VARY $(curl -sI $R -H "Accept: text/turtle" $B/record | tr -d "\r" | grep -ci "^vary")"
  echo "CTYPE $(curl -sI $R $B/record/record-ontology.ttl | tr -d "\r" | grep -i "^content-type" | cut -d" " -f2-)"
  echo "EXAMPLE $(curl -sI $R $B/record/examples/saccheri | head -1 | tr -d "\r" | awk "{print \$2}")"
  echo "MOVED $(curl -sI $R $B/record/cogito.ttl | head -1 | tr -d "\r" | awk "{print \$2}")"
' 2>/dev/null)

while read -r _ path code; do
  [[ $code == 200 ]] && ok "$path -> 200" || bad "$path -> $code"
done < <(grep '^CODE ' <<<"$probe")

while read -r _ path code loc; do
  if [[ $code == 303 && $loc == *.ttl ]]; then ok "$path negotiates -> 303 $loc"
  else bad "$path -> $code $loc (expected 303 to a .ttl)"; fi
done < <(grep '^NEG ' <<<"$probe")

[[ $(grep '^CORS '  <<<"$probe" | awk '{print $2}') -ge 1 ]] \
  && ok "CORS present on the 303 (cross-origin fetch of the IRI works)" \
  || bad "no Access-Control-Allow-Origin on the 303 — browser fetch of the namespace IRI fails"
[[ $(grep '^VARY '  <<<"$probe" | awk '{print $2}') -ge 1 ]] \
  && ok "Vary: Accept on the negotiated response" \
  || bad "no Vary: Accept — caches may serve the wrong representation"
ctype=$(grep '^CTYPE ' <<<"$probe" | cut -d' ' -f2-)
[[ $ctype == *"text/turtle"* && $ctype == *"charset=utf-8"* ]] \
  && ok "Turtle served as $ctype" \
  || bad "Turtle content-type is '$ctype' (expected text/turtle; charset=utf-8)"
[[ $(grep '^EXAMPLE ' <<<"$probe" | awk '{print $2}') == 303 ]] \
  && ok "example IRIs dereference" || bad "bare example IRI did not 303"
[[ $(grep '^MOVED ' <<<"$probe" | awk '{print $2}') == 301 ]] \
  && ok "moved files still redirect" || bad "the /record/cogito.ttl compatibility redirect is gone"

# --- summary ---------------------------------------------------------------
echo
if [[ $fails -eq 0 ]]; then
  echo "server healthy — config, content and dereferencing all as expected."
else
  echo "$fails problem(s) found on $HOST."
fi
exit $(( fails > 0 ))
