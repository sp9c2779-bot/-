# ショットノート（ゴルフのショット記録アプリ）

iPhone の Safari で使う、ゴルフのショット記録 Web アプリです。GitHub Pages（main ブランチのルート）で公開しています。
公開 URL: https://sp9c2779-bot.github.io/-/

利用者とのやり取りは日本語で行う。画面の文言も日本語。主な利用環境は iPhone の Safari（ホーム画面に追加して起動）。

## ファイル構成

| ファイル | 中身 |
|---|---|
| `index.html` | アプリ本体。CSS と、Leaflet などのライブラリと、アプリのソースがすべて入っている |
| `sw.js` | Service Worker。圏外でも起動するためのキャッシュ |
| `assets-1.json` / `assets-2.json` | 航空写真・コース図などのデータ（各約14MB、1行の JSON）。**編集しない** |

アプリのソースは `index.html` の中の `<script type="text/plain" id="source-○○.js">` ブロックにある。

- `source-model.js`: データ構造、距離計算、集計（`stats`）、バックアップの検証（`validateState`）
- `source-regional.js`: ゴルフ場検索、航空写真タイルの URL
- `source-gps-tracker.js`: GPS
- `source-course-transform.js`: コース図と航空写真の位置合わせ
- `source-app.js`: 画面と操作のすべて

ページ末尾のローダーがこれらを ES モジュールとして読み込む。`from './model.js?v=15'` のような import 文の `?v=数字` は、ローダーが置き換えるので変更不要。

## 更新するときのルール（必ず守る）

1. **`sw.js` の `const CACHE='shot-note-N'` の N を 1 つ上げる。** 上げないと、iPhone は古い `index.html` を表示し続ける。
2. `index.html` の「設定」画面にある `SHOT NOTE v1.xx` の表記も 1 つ上げる。
3. `assets-1.json` / `assets-2.json` は変更しない。これらの `?v=16` も、写真データを差し替えない限り変えない（変えると利用者が約29MBを再ダウンロードする）。
4. ショットのデータに新しい項目や値を足すときは、`validateState`（`source-model.js`）がそれを受け入れるように直す。古いバージョンで作ったバックアップも読み込めるようにする（後方互換）。
5. **スコアやパット数の記録機能は追加しない。** 利用者は別の楽天のアプリで記録している。
6. 記録は端末内（IndexedDB）だけに保存する。記録を外部に送信する処理は追加しない。
7. 変更は小さく 1 つずつ。プルリクエストにして、利用者が GitHub アプリで Merge する。プルリクエストの説明には、何が変わるかを日本語で短く書く。

## 確認方法

- ローカルで確認するときは、リポジトリのルートで簡単な HTTP サーバーを起動し（例: `python3 -m http.server 8000`）、`http://localhost:8000/` を開く。`file://` で開くと JSON の読み込みや Service Worker が動かない。
- 画面幅 375px 前後（iPhone）で表示が崩れないこと、ブラウザーのコンソールにエラーが出ないことを確認する。
- 記録 → 再読み込み → 記録が残っている、の流れを確認する。
