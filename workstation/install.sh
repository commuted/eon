#!/usr/bin/env bash
# Install the daily health-check timer into the CURRENT USER's systemd.
#
# Counterpart to server/install.sh: that one installs what runs on the server,
# this one installs what watches it from here. Re-runnable.
#
# Note on linger: a --user timer stops when the user logs out, unless lingering
# is enabled. This script reports the state and tells you the one command to
# change it, rather than enabling it itself -- it needs root, and whether your
# user's services should keep running while logged out is a decision about the
# machine, not about this repository.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
DEST="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"

command -v systemctl >/dev/null || { echo "error: systemctl not found" >&2; exit 2; }
[ -f "$HERE/../deploy.env" ] || {
  echo "error: ../deploy.env missing -- check-server.sh has no host or key" >&2
  echo "       cp deploy.env.example deploy.env && \$EDITOR deploy.env" >&2
  exit 2
}

mkdir -p "$DEST"
install -m 644 "$HERE/eon-check.service" "$HERE/eon-check.timer" "$DEST/"
echo "installed  eon-check.{service,timer} -> $DEST"

systemctl --user daemon-reload
systemctl --user enable --now eon-check.timer
echo "enabled    eon-check.timer"
echo
systemctl --user list-timers eon-check.timer --no-pager

if [ "$(loginctl show-user "$USER" --property=Linger --value 2>/dev/null)" != "yes" ]; then
  echo
  echo "note: lingering is OFF for $USER, so this timer only runs while you are"
  echo "      logged in. To let it run regardless:"
  echo "          sudo loginctl enable-linger $USER"
fi
