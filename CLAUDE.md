# ショットノート（ゴルフのショット記録アプリ）

iPhone の Safari で使う、ゴルフのショット記録 Web アプリです。GitHub Pages（main ブランチのルート）で公開しています。
公開 URL: https://sp9c2779-bot.github.io/-/

利用者とのやり取りは日本語で行う。画面の文言も日本語。主な利用環境は iPhone の Safari（ホーム画面に追加して起動）。

## ファイル構成

| ファイル | 中身 |
|---|---|
| `index.html` | アプリ本体。CSS と、Leaflet などのライブラリと、アプリのソースがすべて入っている |
| `sw.js` | Service Worker。圏外でも起動するためのキャッシュ |
| `assets-1.json` / `assets-2.json` | 朝陽・ミッションバレー・トム・ワトソンの航空写真・コース図など（各約14MB、1行の JSON）。**編集しない** |
| `assets-kaho.json` など `assets-<コース>.json` | 後から追加したコースのデータ。コースごとに別ファイルなので、追加時は利用者がそのファイルだけをダウンロードする |
| `tools/` | コース追加用の PowerShell スクリプトと、各コースのティー・グリーン位置の元データ（`tools/courses/*-holes.json`）。アプリからは読み込まない |

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
7. 変更は小さく 1 つずつ。**確認が済んだら main に直接 push して反映まで済ませてよい**（利用者の希望）。push 後、公開 URL の `sw.js` が新しい `CACHE` 名になったことを確かめてから報告する。
   - main への push が拒否されたときだけ、ブランチからプルリクエストを作り、「GitHub アプリで Merge してください」と伝える。
   - 報告では、何が変わったかを日本語で短く書き、「ホーム画面のアプリを完全に閉じて開くのを 2 回」と更新方法を添える。

## コースを内蔵コースとして追加するとき

1. コース図（公式サイトのホール別画像が望ましい）と PAR・距離・HDCP を集め、航空写真でホールごとのティーとグリーンの位置を読み取って `tools/courses/<key>-holes.json` を作る（形式は `kaho-holes.json` を参照。`dTee`/`dGreen` はコース図画像上の座標）。
2. `tools/build-course.ps1` で `assets-<key>.json` を作る（国土地理院の写真タイルを取得して埋め込む）。
3. `index.html` の `COURSE_OPTIONS` と、`['choyo-cc',...]` の3か所（`DETAIL_IDS` と `validateState`）にコース ID（カタログの `gora-…` をそのまま使う）を追加し、ローダーのアセット一覧に `./assets-<key>.json?v=1` を足す。`sw.js` の `FILES` にも同じものを足す。
4. 位置は目安。利用者は前日に「ホールの枠を調整する」で直せる。

## 確認方法

- ローカルで確認するときは、リポジトリのルートで簡単な HTTP サーバーを起動し（例: `python3 -m http.server 8000`）、`http://localhost:8000/` を開く。`file://` で開くと JSON の読み込みや Service Worker が動かない。
- 画面幅 375px 前後（iPhone）で表示が崩れないこと、ブラウザーのコンソールにエラーが出ないことを確認する。
- 記録 → 再読み込み → 記録が残っている、の流れを確認する。
