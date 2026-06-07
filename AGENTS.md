# AGENTS.md

## プロジェクト概要

ZMK firmware v0.3 ベースの自作キーボード設定。スプリットキーボードのcool642tb-mini。

## ハードウェア構成

| パーツ               | 種別                                        |
| -------------------- | ------------------------------------------- |
| MCU                  | Seeeduino XIAO BLE（左右各1）               |
| キーマトリクス       | 11col x 4row、col2rowダイオード             |
| トラックボール       | PMW3610（右側のみ、SPI接続）                |
| ロータリーエンコーダ | EC11（左側のみ、24 steps）                  |
| 通信                 | BLE スプリット（右=Central、左=Peripheral） |

## ディレクトリ構造

```
config/
├── cool642tb-mini.keymap          # キーマップ・behaviors・combos定義
├── cool642tb-mini.conf            # 左右共通Kconfig（ビルド時に両側へ自動マージ）
└── boards/shields/cool642tb-mini/
    ├── cool642tb-mini.dtsi         # 共通定義（kscan、matrix transform、encoder）
    ├── cool642tb-mini_R.conf       # 右側Kconfig（PMW3610・ZMK Studio等）
    ├── cool642tb-mini_L.conf       # 左側Kconfig
    ├── cool642tb-mini_R.overlay    # 右側オーバーレイ（PMW3610 SPI定義）
    └── cool642tb-mini_L.overlay    # 左側オーバーレイ（EC11有効化）
```

## ビルド

[zmk-nix](https://github.com/lilyinstarlight/zmk-nix) を使用したNixローカルビルド。

### ビルドコマンド

```bash
# ビルド + firmware/ へのコピーを一発実行（日常はこれだけ使う）
nix run .#               # → result/, result-reset/, firmware/ が更新される

# 個別ビルド（成果物は nix store に出力され、firmware/ は更新されない）
nix build .#firmware         # → result/zmk_R.uf2, result/zmk_L.uf2
nix build .#settings-reset   # → result/zmk.uf2

# West依存の更新（west.yml変更時）
nix run .#update

# フラッシュ（WSL: drvfs経由でUF2ブートローダーにコピー）
# ※ flash 前に `nix run .#` を実行して firmware/ を最新化すること
nix run .#flash-win-R     # R側のみ（キーマップ変更は通常これだけで可）
nix run .#flash-win-L     # L側のみ
# ※UF2ドライブのドライブレターは flake.nix の flashDriveLetter で一元管理。
#   Windows側で割り当てられるレター(D:等)は環境により異なるため、
#   必要に応じて flashDriveLetter の値を書き換えること。
```

### 初回セットアップ

1. `zephyrDepsHash` にダミーハッシュが入っている状態で `nix build` を実行
2. エラーメッセージに正しいハッシュが表示されるので `flake.nix` の `zephyrDepsHash` を置換
3. 再度 `nix build` でビルド成功を確認

### AC条件（Acceptance Criteria）

設定変更時のAC条件: **`nix run .#` が exit code 0 で完了し、`firmware/zmk_R.uf2`, `firmware/zmk_L.uf2`, `firmware/settings_reset.uf2` が更新されること**

## キーマップ構成

### レイヤー一覧（cool642tb-mini.keymap）

| #   | 名前       | 用途                                      |
| --- | ---------- | ----------------------------------------- |
| 0   | DEFAULT    | 通常入力                                  |
| 1   | FUNCTION   | Fキー・矢印・ナビゲーション               |
| 2   | NUM        | 数字・記号                                |
| 3   | MOUSE      | マウスボタン・ブラウザ操作                |
| 4   | SCROLL     | スクロール（PMW3610 scroll-layersで使用） |
| 5   | SYSTEM     | 音量・ウィンドウ操作                      |
| 6   | BOARD_CTRL | BLE接続管理・ブートローダ                 |
| 7   | OFFICE     | PowerPoint・Excel・Outlookショートカット  |
| 8   | JIS_NUM    | JIS配線向け数字・記号                      |
