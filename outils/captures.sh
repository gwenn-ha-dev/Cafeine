#!/bin/bash
# README captures — CHARTE.md §12. `make shots` delegates here.
#
# Cafeine has no window: what there is to show is its menu, opened at launch by
# `-showMenu YES`, and its About panel (`-showAbout YES`). The menu sits above
# the level `capturer.sh` looks at, so it is found by `outils/fenetre-menu.swift`
# and captured here, alone and without its shadow. Nothing personal is shown.
set -euo pipefail
cd "$(dirname "$0")/.."
capturer=${CHARTE:-../../Charte}/outils/capturer.sh
app=build/Cafeine.app
[ -d "$app" ] || { echo "captures: build the app first (make package)" >&2; exit 1; }
pgrep -x Cafeine >/dev/null && { echo "captures: quit the running Cafeine first" >&2; exit 1; }

launch() {  # launch <language> <args…>
  local lang=$1; shift
  pkill -x Cafeine 2>/dev/null || true
  sleep 2   # the previous instance must be gone, or the new menu may not open
  open -n "$app" --args -AppleLanguages "($lang)" -AppleLocale "${lang}_$( [ "$lang" = en ] && echo GB || echo FR )" "$@"
}

menu() {  # menu <out> — the menu opened by the last launch
  local id=
  for _ in $(seq 1 20); do
    id=$(swift outils/fenetre-menu.swift 2>/dev/null) && [ -n "$id" ] && break
    id=; sleep 1
  done
  [ -n "$id" ] || { swift outils/fenetre-menu.swift; exit 1; }
  mkdir -p "$(dirname "$1")"
  screencapture -x -o -l "$id" "$1"
  echo "→ $1"
}

for lang in en fr; do
  suffix=$( [ "$lang" = en ] && echo "" || echo ".fr" )
  launch "$lang" -activate 7200 -showMenu YES
  menu "docs/img/active$suffix.png"
  launch "$lang" -showMenu YES
  menu "docs/img/inactive$suffix.png"
  launch "$lang" -showAbout YES
  "$capturer" Cafeine "docs/img/about$suffix.png"
done
pkill -x Cafeine 2>/dev/null || true
