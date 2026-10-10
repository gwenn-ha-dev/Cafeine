# Changelog

All notable changes to Cafeine are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning: [SemVer](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] — 2026-10-10

### Added
- Menu bar app that keeps the Mac awake through a power assertion
  (`IOPMAssertionCreateWithName`), with no child process.
- Click to toggle; menu with durations from 15 minutes to 8 hours, or no limit.
- Allow Display Sleep: the system stays awake, the screen may turn off.
- Open at Login (`SMAppService`).
- `-activate <seconds>` launch argument, `0` for no limit.
- English, French, German, Spanish and Italian.

[Unreleased]: https://github.com/gwenn-ha-dev/Cafeine/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/gwenn-ha-dev/Cafeine/releases/tag/v1.0.0
