# Cafeine — agent context

## What this is

Keeps the Mac awake from the menu bar: one click on the cup, and the Mac stops
going to sleep until the next click or the end of the chosen duration.

Platform: macOS 13+. Build system: spm. Bundle ID `dev.gwennha.Cafeine`.

## Build and test

```sh
make build   # release, warnings are errors
make test
make lint    # charter compliance — run before declaring anything done
```

Never invoke `swift build`, `xcodebuild` or a build script directly; go through
the `Makefile`. It is the same interface in every project here.

## Invariants — do not break these

- **One power assertion, held directly.** `KeepAwake` calls
  `IOPMAssertionCreateWithName` / `IOPMAssertionRelease`. No `caffeinate` child
  process, no timer that re-asserts: that design is what this app replaces. The
  expiry is one cancellable `Task`, cancelled whenever the assertion changes.
- **Light by construction.** No notifications, no update framework, no SwiftUI,
  no settings window. About 12 MB footprint (`footprint $(pgrep -x Cafeine)`);
  a change that grows it noticeably needs a reason.
- **The menu is rebuilt on every opening** (`menuNeedsUpdate`) and holds nothing
  in between.
- **No hard-coded user-visible strings.** Everything goes through
  `Resources/<language>.lproj/Localizable.strings`, hierarchical keys
  (`menu.quit`), in `en`, `fr`, `de`, `es` and `it`. Adding a string means adding
  every translation in the same change; `LocalizationTests` fails otherwise.
  Durations go through `Duration.UnitsFormatStyle`, never a hand-built string.
- **No build artefacts committed.** No `.app`, no `build/`, no `.build/`.
- **No new dependency** without saying so explicitly and documenting it in the
  README's *Dependencies* section.
- **`README.md` and `README.fr.md` stay in sync.** Editing one means editing
  the other.
- **The icon is generated**, never hand-placed: `outils/icone.swift` is the
  source, `make icon` rebuilds `Resources/AppIcon.icns`.
- Identifiers, commit messages and both READMEs are in **English**; comments may
  be in English or French (charter §2).

## Launch arguments

`-activate <seconds>` (`0` = no limit) is a feature, documented in the README.
`-showMenu YES` and `-showAbout YES` exist for `outils/captures.sh`.

## Public identity and releases (charter §12)

- Commit as `gwenn-ha-dev <13298867+gwenn-ha-dev@users.noreply.github.com>` (set
  in this repo's git config) and in UTC: `TZ=UTC git commit …`. No personal name,
  email or `/Users/…` path in tracked files. `../../Charte/outils/identite.sh .` checks.
- A release: `make package && make sign && make dmg && make shots && make release-check`,
  then tag `v<version>` and attach `build/Cafeine-<version>.dmg` — see
  `../../Charte/DISTRIBUTION-AGENT.md`, phase 3. The version is
  `CFBundleShortVersionString` in `Resources/Info.plist`.
- The bundle is assembled by `outils/package.sh` from a universal SwiftPM build
  (arm64 + x86_64), signed ad hoc with no entitlements; `make sign` re-signs it
  with the Developer ID and the hardened runtime. Nothing in the app needs an
  entitlement: power assertions and `SMAppService.mainApp` work without one.
- Captures: Cafeine has no window. `outils/captures.sh` opens the menu at launch
  and finds it with `outils/fenetre-menu.swift`, because `capturer.sh` only
  looks at level-0 windows and a menu lives at the pop-up menu level. The About
  panel is a normal window and goes through `capturer.sh`.

## Layout

```
.github/workflows/ci.yml
Package.swift
Sources/Cafeine/      main.swift, AppDelegate.swift (status item, menu), KeepAwake.swift (the assertion)
Tests/CafeineTests/   the assertion as the system sees it, localization tables
Resources/            Info.plist, AppIcon.icns, <language>.lproj/Localizable.strings
docs/img/             README captures (<view>.png, <view>.fr.png), social-preview.jpg
site/index.html       the GitHub Pages page
outils/               package.sh, icone.swift, captures.sh, fenetre-menu.swift
```

## The charter

The full norm this project follows lives at `../../Charte/CHARTE.md`.
