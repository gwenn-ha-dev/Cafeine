# Contributing to Cafeine

Thanks for taking the time. This project follows the gwenn-ha-dev project
charter — the short version is below.

## Before you start

- Open an issue first for anything beyond a typo fix.
- One concern per pull request.

## Working on it

```sh
make build     # release build, warnings are errors
make test      # test suite
make lint      # charter compliance — must pass
```

## Conventions

- **Language.** Code, commit messages and `README.md` are in English; comments
  may be in English or French.
  `README.fr.md` carries the French version and must stay in sync.
- **Commits.** `<Scope>: <what changes>`, imperative, 72 characters max on the
  first line. Example: `Sidebar: combine facet rows with cmd-click`.
- **Branches.** `feat/…`, `fix/…`, `docs/…`. Never commit directly to `main`.
- **Strings.** No user-visible string is hard-coded. Everything goes through
  `Resources/<language>.lproj/Localizable.strings` (`en`, `fr`, `de`, `es`, `it`):
  a new key goes into every language in the same change. `make test` and
  `make lint` fail if a key is missing.
- **Dependencies.** Default is none. Adding one requires a justification in the
  README's *Dependencies* section.
- **Build artefacts** are never committed.

## Releasing

1. Update `CHANGELOG.md`.
2. Bump `CFBundleShortVersionString` in `Resources/Info.plist`.
3. `make package && make sign && make dmg && make shots && make release-check`.
4. Tag `v<major>.<minor>.<patch>` and attach `build/Cafeine-<version>.dmg`.
