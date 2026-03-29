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
└── boards/shields/Test/
    ├── cool642tb-mini.dtsi         # 共通定義（kscan、matrix transform、encoder）
    ├── cool642tb-mini_R.conf       # 右側Kconfig（PMW3610・ZMK Studio等）
    ├── cool642tb-mini_L.conf       # 左側Kconfig
    ├── cool642tb-mini_R.overlay    # 右側オーバーレイ（PMW3610 SPI定義）
    └── cool642tb-mini_L.overlay    # 左側オーバーレイ（EC11有効化）
```

## ビルド

GitHub Actions で `zmkfirmware/zmk@v0.3.0` のワークフローを使用。push時に自動ビルド。
ファームウェアは `firmware/` または Actions Artifacts から取得。

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
