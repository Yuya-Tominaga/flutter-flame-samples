# flutter-flame-samples

Flutter [Flame](https://flame-engine.org/) の検証用サンプル集です。単一のカタログ型アプリから各サンプルを起動できます。

## Live previews

| 対象 | URL |
| --- | --- |
| `main` | https://yuya-tominaga.github.io/flutter-flame-samples/ |
| PR | https://yuya-tominaga.github.io/flutter-flame-samples/pr-preview/pr-\<番号\>/ |
| 端末選択リンク | 各プレビューの [`devices.html`](https://yuya-tominaga.github.io/flutter-flame-samples/devices.html) |

GitHub Pages は **profile ビルド**で公開しています（`device_preview` 3.x は release ビルドでは完全に無効になるため）。そのため release より容量が大きく、動作も重くなります。

最初の PR を `main` にマージするまでは、ルート URL は 404 になります（`gh-pages` に PR プレビューしか無い状態）。

PR プレビューは fork からの PR ではデプロイされません（`rossjrw/pr-preview-action` v1 の仕様）。Dependabot の PR もプレビュー対象外です（check のみ実行）。

## 必要環境

- [mise](https://mise.jdx.dev/)（Flutter SDK を `.mise.toml` で固定）
- Xcode（iOS）
- Android SDK（Android）
- Chrome（Web）

Flutter の最新 stable は **3.47.5** です。

## セットアップ

```bash
mise install
flutter pub get
```

Google Storage へのアクセスが 403 になる環境では、一時的にミラーを指定できます。

```bash
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
export PUB_HOSTED_URL=https://pub.flutter-io.cn
```

## 実行

```bash
# iOS
flutter run -d ios

# Android
flutter run -d android

# Web（ローカル）
flutter run -d chrome
```

### DevicePreview（ローカル）

`lib/main.dart` は debug / profile で `DevicePreview.enable()` します。Flutter DevTools の **device_preview** タブから端末を切り替えてください。

### DevicePreview（GitHub Pages）

Pages 用エントリは `lib/main_preview.dart` です。端末は URL クエリで指定します（アプリ内 UI はありません）。

```text
https://yuya-tominaga.github.io/flutter-flame-samples/?device=iphone-16&orientation=portrait#/
```

対応 `device` 値: `iphone-16`, `iphone-se3`, `ipad-pro-11`, `pixel-9`, `galaxy-s25`  
対応 `orientation` 値: `portrait`（省略時）, `landscape`

未知の値を渡すとアプリは起動せず、エラーはブラウザのコンソールに出ます。端末選択リンクは [`web/devices.html`](web/devices.html) を参照してください。

ローカルでの profile 確認例:

```bash
flutter run -d chrome --profile -t lib/main_preview.dart
# ブラウザで ?device=iphone-16#/ を付けて開く
```

## サンプルの追加手順

1. `lib/samples/<name>/` に Flame ゲームを実装する
2. [`lib/samples/samples.dart`](lib/samples/samples.dart) の `samples` リストに `Sample` を追加する
3. 必要なら `test/` に `flame_test` / widget test を追加する

共通の画面枠は [`SampleScaffold`](lib/shared/sample_scaffold.dart) です。存在しないサンプル id はエラー画面を表示し、暗黙のリダイレクトはしません。

- 画面の向きを固定したいサンプルは `Sample.preferredOrientations` を指定します（サンプル表示中だけ固定し、離れると解除）
- Flutter の overlay 画面を使うゲームは `HasSampleOverlays` を実装すると `GameWidget` に登録されます

## サンプル一覧

| id | 内容 |
| --- | --- |
| `basic-movement` | キーボード / タップ / ドラッグで円を動かす |
| `endless-breakout` | 迫ってくるブロックを崩し続けるエンドレス型レンガ崩し（縦持ち固定） |

`endless-breakout` の効果音（`assets/audio/endless_breakout/*.wav`）はスクリプトで生成しています。

```bash
dart run tool/generate_endless_breakout_sfx.dart
```

## 品質チェック

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

Lint は `very_good_analysis` を使います。ルールの無効化は行いません。合わないルールが出たら相談してください。

## CI / CD

- PR: format / analyze / test → Web profile を `gh-pages` の `pr-preview/pr-<N>/` にデプロイ（PR コメントに URL）
- `main` push: format / analyze / test → Web profile を `gh-pages` ルートにデプロイ（`pr-preview/` は残す）
- Dependabot: `pub` と `github-actions` を週次更新

## Flutter SDK の更新

Dependabot は pub / Actions のみ更新します。Flutter SDK は手動です。

1. https://docs.flutter.dev/release/archive などで最新 stable を確認する
2. `.mise.toml` の `flutter` を更新する
3. `mise install`
4. `flutter pub get` / `flutter analyze` / `flutter test` で確認する
5. PR を出す

## GitHub Pages の有効化

初回のみリポジトリ設定が必要です。

1. Settings → Pages
2. Build and deployment → Source: **Deploy from a branch**
3. Branch: `gh-pages` / folder: `/ (root)`

CI が初めて `gh-pages` を作ったあと（通常は最初の PR プレビュー）に設定できます。
