#!/bin/bash
# Construit build/Cafeine.app. Aucune dépendance : swift des Command Line Tools suffit.
#
#   ./outils/package.sh            → build/Cafeine.app, signature ad hoc
#   ./outils/package.sh install    → idem, puis remplace /Applications/Cafeine.app et la lance
set -euo pipefail
cd "$(dirname "$0")/.."

# Binaire universel : le .dmg doit s'ouvrir sur un Mac Intel aussi.
swift build -c release --arch arm64 --arch x86_64
BIN="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)/Cafeine"
APP="build/Cafeine.app"

# L'icône est fabriquée par un script, refaite seulement si sa source a bougé.
if [ ! -f Resources/AppIcon.icns ] || [ outils/icone.swift -nt Resources/AppIcon.icns ]; then
  swift outils/icone.swift "$PWD"
  iconutil -c icns Resources/AppIcon.iconset -o Resources/AppIcon.icns
  rm -rf Resources/AppIcon.iconset
fi

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Cafeine"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
# Toutes les langues : macOS ne choisit que parmi celles présentes dans le paquet.
cp -R Resources/*.lproj "$APP/Contents/Resources/"
printf 'APPL????' > "$APP/Contents/PkgInfo"

# Ad hoc ici ; `make sign` la remplace par le Developer ID et fait notariser (charte §12).
codesign --force --sign - --timestamp=none "$APP"
codesign --verify --verbose=1 "$APP"
echo "→ $PWD/$APP  (signature ad hoc — make sign pour le Developer ID)"

if [ "${1:-}" = "install" ]; then
  pkill -x Cafeine 2>/dev/null || true
  rsync -a --delete "$APP/" /Applications/Cafeine.app/
  open /Applications/Cafeine.app
  echo "→ /Applications/Cafeine.app mise à jour"
fi
