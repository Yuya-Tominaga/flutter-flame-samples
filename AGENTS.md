# AGENTS.md

Guidance for AI coding agents working in this repository.

## Project

- Single Flutter app catalog for Flame experiments
- Platforms: iOS, Android, Web
- Flutter SDK is pinned in `.mise.toml` (currently 3.47.5)
- Package name: `flutter_flame_samples`
- Org / application id prefix: `io.github.yuyatominaga`

## Commands

Always prefer `mise exec --` (or enter the mise environment) so the pinned Flutter is used.

```bash
mise install
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter build web --profile -t lib/main_preview.dart --base-href /flutter-flame-samples/
flutter build apk --debug
flutter build ios --debug --no-codesign
```

If Google Storage returns 403 while fetching Flutter artifacts or packages:

```bash
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
export PUB_HOSTED_URL=https://pub.flutter-io.cn
```

## Layout

```text
lib/
  main.dart                 # local entry (DevicePreview via DevTools)
  main_preview.dart         # GitHub Pages entry (query-driven DevicePreview)
  app/                      # MaterialApp + go_router
  catalog/                  # sample list
  shared/                   # Sample model + SampleScaffold
  samples/                  # one folder per sample + samples.dart registry
  preview/device_query.dart # URL query → DevicePreset map
web/devices.html            # static device-link page for Pages
test/                       # flame_test + widget tests
```

## Adding a sample

1. Create `lib/samples/<name>/`
2. Register a `Sample` in `lib/samples/samples.dart`
3. Keep ids unique (`kebab-case`)
4. Add tests when behavior is non-trivial
5. Do not silently redirect unknown sample ids

## DevicePreview rules

- `device_preview` 3.x has no in-app toolbar; controls are DevTools or `DevicePreview.controller`
- Release builds disable simulation completely
- Pages must use **profile** builds via `lib/main_preview.dart`
- Only reference explicit presets in `previewDevicePresets` (do not use `DevicePresets.byId` / `.all`)
- Unknown `device` / `orientation` query values must throw `StateError`

## Quality

- Lint: `package:very_good_analysis/analysis_options.yaml`
- Do not disable analyzer rules, skip tests, or hide type errors without an explicit user request
- Commit `pubspec.lock`
- Prefer failing loudly over fallbacks / swallowed errors

## CI notes

- PR preview Action cannot deploy from forks or Dependabot PRs
- `gh-pages` writers share one concurrency group to avoid push races
- Deployed web output must include `.nojekyll`
