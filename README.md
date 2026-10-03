# REAPER FL Workflow

<p align="center">
  <a href="https://github.com/SakiikaVR/REAPER-FL-Workflow/releases/latest">
    <img src="https://img.shields.io/github/v/release/SakiikaVR/REAPER-FL-Workflow?style=for-the-badge&label=%E2%AC%87%20Installer&color=ff9f0a" alt="最新版をダウンロード">
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/License-MIT-blue?style=for-the-badge" alt="MIT License">
  </a>
</p>

REAPER 7の操作感と見た目を、FL Studio寄りにまとめて適用するWindows用セットアップです。ピアノロール、ホイール操作、トラック追加、Gridbox、ダークモードを一度に設定します。フォントと起動ロゴはREAPER標準のままにします。

現在の仕様は **v1.1.4** です。

## 特長

- ピアノロールの空白を左ドラッグしてノートを作成・伸縮
- 直前に置いた、または選択したノートの長さを次の入力へ記憶
- 右クリック・右ドラッグでノートとCCをすぐ削除
- `Ctrl`＋ドラッグで矩形選択、`Shift`＋ドラッグでノート複製
- 通常画面とMIDIエディターのホイールを縦スクロールへ統一
- `Ctrl`＋ホイールで横方向をズーム
- 空きトラック欄の「＋」からソフトシンセトラックを直接追加
- Gridboxを BPM 表示と重ならない位置に配置し、REAPER起動時に自動実行
- ミキサーのドッキング状態と再生コントローラーの位置を設定
- ReaperDarkModeでWindows標準ダイアログを暗色化
- フォント・テーマの追加ファイルとカスタム起動ロゴを配布しない

## インストール

動作対象は **Windows 10 / 11、REAPER 7.80 x64** です。

1. 作業中のプロジェクトを保存し、REAPERを終了します。
2. 既存の REAPER 設定を残したい場合は、`%APPDATA%\REAPER` を別の場所にコピーしておきます。EXE 版は `reaper-kb.ini`、`reaper-menu.ini`、`reaper-mouse.ini`、`reaper-extstate.ini`、`Scripts\__startup.lua` を上書きします。`REAPER.ini` は eiedit の INI 設定機能でドッキングの 7 項目だけを更新し、音声デバイス・言語設定を残します。
3. [最新リリース](https://github.com/SakiikaVR/REAPER-FL-Workflow/releases/latest)から `REAPER-FL-Workflow-Direct-v1.1.4.EXE` をダウンロードし、ダブルクリックします。
4. 画面に従ってインストールします。インストーラーはファイルを REAPER の設定フォルダーへ直接コピーして終了します。
5. REAPERを起動して動作を確認します。初回起動時に ReaScript が REAPER のアクションへ登録されます。

旧版で起動ロゴを設定した場合は、先に旧版のアンインストーラーで元の `REAPER.ini` へ戻してください。同名の `[reaper]` セクションが複数あると、eiedit の INI 設定が意図した項目を更新できない場合があります。

ZIP版を使う場合は、`REAPER-FL-Workflow-v1.1.4.zip` を「すべて展開」し、`Install.cmd` をダブルクリックします。Smart App ControlはEXE内部のスクリプトやDLLも検査するため、警告が出ないことは保証できません。確実な対策には、配布する実行コードへの信頼された証明書による署名が必要です。

REAPERの設定は `%APPDATA%\REAPER` に保存します。EXE版は別の展開フォルダーを作りません。

## 操作

### ピアノロール

| 操作 | 動作 |
|---|---|
| 空白を左クリック | ノートを配置 |
| 空白を左ドラッグ | ノートを配置して長さを変更 |
| `Ctrl`＋左ドラッグ | 矩形選択 |
| ノートを左ドラッグ | 移動 |
| `Shift`＋ノートを左ドラッグ | 複製 |
| ノート端を左ドラッグ | 長さを変更 |
| 右クリック・右ドラッグ | ノート／CCを即時削除 |
| `Ctrl`＋右ドラッグ | ノート／CCを矩形選択 |

ノートを伸ばした後、または既存ノートを一度選択した後に空白をクリックすると、その長さで次のノートを置けます。

この設定はMIDIエディターの **オプション → Drawing or selecting a note sets the new note length** でも確認できます。MIDIエディターが閉じた状態でインストールした場合も、次に開いたときに有効化されます。

### ホイール

| 場所 | ホイール | `Ctrl`＋ホイール |
|---|---|---|
| 通常画面 | 縦スクロール | 横方向ズーム |
| MIDIエディター | 縦スクロール | 横方向ズーム |

### シンセトラック

左側の空きトラック欄にある「＋」をクリックすると、`ソフトシンセを新規トラックに挿入`が直接開きます。

## 元に戻す

REAPERを終了し、インストール前に保存した `%APPDATA%\REAPER` のコピーから設定を戻してください。ZIP版の `Install.cmd` で導入した場合は、そのとき作成された `%APPDATA%\REAPER\ReaperFLWorkflow-Uninstall.cmd` を使えます。

## REAPERを日本語化する

[ReaperJPN-Phroneris](https://github.com/Phroneris/ReaperJPN-Phroneris)にはライセンス表記がないため、このリポジトリには日本語化ファイルを同梱していません。公式配布元から各自で導入してください。

1. [ReaperJPN-Phronerisの最新Release](https://github.com/Phroneris/ReaperJPN-Phroneris/releases/latest)を開きます。
2. `JPN_Phroneris.zip` をダウンロードして展開します。
3. Windows用の `JPN_Phroneris.ReaperLangPack` をダブルクリックします。
4. REAPERの確認画面でインストールを許可し、REAPERを再起動します。

翻訳の更新状況やトラブルシューティングは[公式Wiki](https://github.com/Phroneris/ReaperJPN-Phroneris/wiki)を参照してください。

## 変更される場所

| 対象 | 内容 |
|---|---|
| `reaper-mouse.ini` / ExtState | FL風ピアノロール操作 |
| `reaper-kb.ini` | 通常画面・MIDIエディターのホイール操作 |
| `reaper-menu.ini` | Empty TCP area toolbarの「＋」 |
| `REAPER.ini` | ミキサーと再生コントローラーの表示・ドッキング設定の 7 項目 |
| `Scripts/FLPianoRoll` | 自作ReaScript |
| `Scripts/FTC/Adaptive grid` | Gridbox |
| `Scripts/__startup.lua` | Gridboxの自動起動 |
| `UserPlugins` | DarkMode、js_ReaScriptAPI |

## 開発と確認

インストーラーは別のリソースフォルダーを指定できるため、実環境を変更せずに検証できます。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Install.ps1 `
  -ResourcePath .\.test-resource
```

配布ZIPを作成する場合は次を実行します。

```powershell
.\Build-Release.ps1
```

## ファイル構成

```text
├─ Build-Release.ps1               # 配布ZIPの作成
├─ Install.cmd / Install.ps1       # 展開版インストーラー
├─ Uninstall.cmd / Uninstall.ps1   # バックアップから復元
├─ payload/
│  ├─ Scripts/                     # FLピアノロールとGridbox
│  └─ UserPlugins/                 # x64拡張DLL
├─ third_party/                    # 外部ライセンス
├─ THIRD_PARTY_NOTICES.md
└─ LICENSE
```

## 外部コンポーネント

- [ReaperDarkMode v1.1.0](https://github.com/RobKor77/ReaperDarkMode) — MIT
- [Reaper-Tools / Gridbox](https://github.com/iliaspoulakis/Reaper-Tools) — MIT
- [js_ReaScriptAPI v1.310](https://github.com/juliansader/ReaExtensions) — MIT

詳しい著作権表示は[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)と[`third_party/`](third_party/)に収録しています。REAPER本体と標準テーマは配布物に含みません。

## ライセンス

[MIT License](LICENSE)

REAPERはCockos Incorporated、FL StudioはImage-Lineの製品です。各名称は互換性と操作方法の説明にのみ使用しています。本プロジェクトは両社の公式製品ではありません。
