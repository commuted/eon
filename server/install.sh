#!/usr/bin/env bash
# Pull the published site from git and install it. RUNS ON THE SERVER.
#
# The repository commits its build output (site/), so the server needs only git
# and rsync -- no Python, no build step, no toolchain to keep current. What is
# in git is exactly what gets served.
#
# Safety, in the order it matters:
#
#   * The nginx config is tested BEFORE it is kept. If `nginx -t` fails, the
#     previous config is restored and the script aborts having changed nothing
#     that matters. This is the specific failure that took the site down on
#     2026-07-31: a config that could not load, installed anyway, leaving nginx
#     unable to start at all.
#   * conf.d is checked for strays. Anything else matching *.conf is loaded too,
#     and a second file declaring `default_server` is fatal to the whole server.
#   * If nginx is down, this starts it rather than reloading; a failed reload on
#     a dead service is silent.
#   * Content is synced only after the config is known good.
#
# Usage, on the server:
#     ./install.sh                 # pull the default branch and install
#     ./install.sh --dry-run       # show what would change, touch nothing
#     ./install.sh --ref v1.2      # install a specific tag/branch/commit
#
# Bootstrap (first run, before the checkout exists):
#     sudo dnf install -y git rsync
#     git clone https://github.com/commuted/eon.git /opt/eon
#     /opt/eon/server/install.sh
set -euo pipefail

REPO_URL="${EON_REPO:-https://github.com/commuted/eon.git}"
CHECKOUT="${EON_CHECKOUT:-/opt/eon}"
REF="${EON_REF:-}"
WEBROOT="${EON_WEBROOT:-/var/www/html}"
CONF_NAME="epistemic-ontology.net.conf"
CONF_DIR="/etc/nginx/conf.d"
WEB_USER="${EON_WEB_USER:-nginx}"
DRY=0

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1 ;;
    --ref) REF="${2:-}"; shift ;;
    -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
  shift
done

say()  { printf '\n\033[1m%s\033[0m\n' "$*"; }
info() { printf '  %s\n' "$*"; }
die()  { printf '\n\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }
run()  { if [ "$DRY" = 1 ]; then printf '  would: %s\n' "$*"; else "$@"; fi; }

[ "$DRY" = 1 ] && say "DRY RUN — nothing will be changed"

# --- 1. fetch --------------------------------------------------------------
say "1. source"
command -v git   >/dev/null || die "git is not installed (sudo dnf install -y git)"
command -v rsync >/dev/null || die "rsync is not installed (sudo dnf install -y rsync)"

if [ ! -d "$CHECKOUT/.git" ]; then
  info "cloning $REPO_URL -> $CHECKOUT"
  run sudo git clone --quiet "$REPO_URL" "$CHECKOUT"
  run sudo chown -R "$(id -un):$(id -gn)" "$CHECKOUT"
fi

cd "$CHECKOUT"
before=$(git rev-parse --short HEAD 2>/dev/null || echo none)
git fetch --quiet --tags origin
target="${REF:-origin/$(git symbolic-ref --quiet --short HEAD 2>/dev/null || echo master)}"
git rev-parse --quiet --verify "$target^{commit}" >/dev/null || die "no such ref: $target"

# Hard reset, deliberately: the checkout is a deployment artifact, not a
# workspace. Local edits on the server are exactly the drift we do not want.
run git reset --quiet --hard "$target"
run git clean -qfd
after=$(git rev-parse --short HEAD)
info "$before -> $after  ($(git log -1 --format=%s | cut -c1-64))"

[ -f "$CHECKOUT/site/index.html" ] || die "site/index.html missing — is this the right repository?"
[ -f "$CHECKOUT/nginx/$CONF_NAME" ] || die "nginx/$CONF_NAME missing"
info "$(find "$CHECKOUT/site" -type f | wc -l) files to publish"

# --- 2. config, tested before it is kept -----------------------------------
say "2. nginx config"
strays=$(find "$CONF_DIR" -maxdepth 1 -name '*.conf' ! -name "$CONF_NAME" -printf '%f\n' 2>/dev/null || true)
if [ -n "$strays" ]; then
  echo "$strays" | sed 's/^/  STRAY: /'
  die "another *.conf is present in $CONF_DIR and WILL be loaded.
       If it declares default_server, nginx will refuse to start.
       Move it aside (e.g. mv X.conf X.conf.disabled) and re-run."
fi
info "conf.d holds no strays"

if sudo cmp -s "$CHECKOUT/nginx/$CONF_NAME" "$CONF_DIR/$CONF_NAME" 2>/dev/null; then
  info "config already current — not touching it"
else
  backup="/var/backups/nginx-$CONF_NAME.$(date +%Y%m%d-%H%M%S)"
  run sudo mkdir -p /var/backups
  if [ -f "$CONF_DIR/$CONF_NAME" ]; then
    run sudo cp -a "$CONF_DIR/$CONF_NAME" "$backup"
    info "backed up current config -> $backup"
  else
    backup=""
    info "no existing config to back up"
  fi
  run sudo install -m 0644 -o root -g root "$CHECKOUT/nginx/$CONF_NAME" "$CONF_DIR/$CONF_NAME"
  info "installed new config"

  if [ "$DRY" = 0 ]; then
    if sudo nginx -t >/tmp/eon-nginx-t.log 2>&1; then
      info "nginx -t passes"
    else
      printf '\n\033[31mnginx -t FAILED — rolling back\033[0m\n'
      sed 's/^/    /' /tmp/eon-nginx-t.log
      if [ -n "$backup" ]; then
        sudo cp -a "$backup" "$CONF_DIR/$CONF_NAME"
        sudo nginx -t >/dev/null 2>&1 \
          && echo "  restored the previous config; it tests clean" \
          || echo "  RESTORED CONFIG ALSO FAILS — the server needs manual attention"
      else
        sudo rm -f "$CONF_DIR/$CONF_NAME"
        echo "  removed the config that failed (there was no previous one)"
      fi
      die "config not installed; content was NOT touched"
    fi
  fi
fi

# --- 3. content ------------------------------------------------------------
say "3. content"
run sudo mkdir -p "$WEBROOT"
if [ "$DRY" = 1 ]; then
  sudo rsync -a --delete --itemize-changes --dry-run \
    "$CHECKOUT/site/" "$WEBROOT/" | head -30
else
  changed=$(sudo rsync -a --delete --itemize-changes "$CHECKOUT/site/" "$WEBROOT/" | wc -l)
  sudo chown -R "$WEB_USER:$WEB_USER" "$WEBROOT"
  sudo find "$WEBROOT" -type d -exec chmod 755 {} +
  sudo find "$WEBROOT" -type f -exec chmod 644 {} +
  info "$changed path(s) changed; $(find "$WEBROOT" -type f | wc -l) files now served"
fi

# --- 4. bring nginx up -----------------------------------------------------
say "4. nginx"
state=$(systemctl is-active nginx 2>/dev/null || true)
if [ "$state" = active ]; then
  run sudo systemctl reload nginx
  info "reloaded"
else
  info "nginx is $state — starting rather than reloading"
  run sudo systemctl start nginx
fi
run sudo systemctl enable --quiet nginx
[ "$DRY" = 0 ] && info "now: $(systemctl is-active nginx) / $(systemctl is-enabled nginx)"

# --- 5. prove it works -----------------------------------------------------
if [ "$DRY" = 0 ]; then
  say "5. verify"
  R=(--resolve epistemic-ontology.net:443:127.0.0.1)
  B=https://epistemic-ontology.net
  fails=0
  check() { # check <label> <expected> <actual>
    if [ "$2" = "$3" ]; then printf '  ok    %-34s %s\n' "$1" "$3"
    else printf '  FAIL  %-34s got %s, want %s\n' "$1" "$3" "$2"; fails=$((fails+1)); fi
  }
  check "GET /"            200 "$(curl -s  "${R[@]}" -o /dev/null -w '%{http_code}' "$B/")"
  check "GET /blog/"       200 "$(curl -s  "${R[@]}" -o /dev/null -w '%{http_code}' "$B/blog/")"
  check "/record negotiates" 303 "$(curl -sI "${R[@]}" -H 'Accept: text/turtle' "$B/record" | head -1 | tr -d '\r' | awk '{print $2}')"
  check "/arith negotiates"  303 "$(curl -sI "${R[@]}" -H 'Accept: text/turtle' "$B/arith"  | head -1 | tr -d '\r' | awk '{print $2}')"
  check "CORS on the 303"    1 "$(curl -sI "${R[@]}" -H 'Accept: text/turtle' -H 'Origin: https://example.com' "$B/record" | grep -ci 'access-control-allow-origin')"
  ctype=$(curl -sI "${R[@]}" "$B/record/record-ontology.ttl" | tr -d '\r' | grep -i '^content-type' | cut -d' ' -f2-)
  check "Turtle content-type" "text/turtle; charset=utf-8" "$ctype"

  if [ "$fails" -gt 0 ]; then
    die "$fails verification check(s) failed — the site is installed but not behaving"
  fi
  printf '\n\033[32minstalled and verified\033[0m  %s -> %s\n' "$before" "$after"
fi
