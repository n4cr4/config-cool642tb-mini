# AGENTS.md

## プロジェクト概要

ZMK firmware ベースの自作キーボード設定。スプリットキーボードのcool642tb-mini。

- **ZMK 本体**: `na-ka-no/zmk` fork の `for-cool642tb_mini` ブランチを使用
- **PMW3610 ドライバ**: `na-ka-no/zmk-pmw3610-driver` に依存
- **ZMK Studio**: 有効（`enableZmkStudio = true` / `CONFIG_ZMK_STUDIO=y`）

依存の実体は `config/west.yml` を参照。

## ハードウェア構成

| パーツ               | 種別                                        |
| -------------------- | ------------------------------------------- |
| MCU                  | Seeeduino XIAO BLE（左右各1）               |
| キーマトリクス       | 11col x 4row、col2rowダイオード             |
| トラックボール       | PMW3610（右側のみ、SPI接続）                |
| ロータリーエンコーダ | EC11（左側のみ、24 steps）                  |
| 通信                 | BLE スプリット（右=Central、左=Peripheral） |

### PMW3610 主要設定（`cool642tb-mini_R.conf`）

| パラメータ                   | 値            | 備考                                          |
| ---------------------------- | ------------- | --------------------------------------------- |
| CPI                          | 600           | dividor=1                                     |
| Orientation                  | 180°          |                                               |
| Polling rate                 | 125Hz         | software polling                              |
| Scroll                       | X反転         | `scroll-layers = <4>`（SCROLLレイヤで発動）   |
| Automouse timeout            | 800ms         |                                               |
| Movement threshold           | 2             |                                               |
| Run downshift / Rest1 sample | 3264ms / 20ms | 省電力（Deep Sleep と併用）                   |

## ディレクトリ構造

```
.
├── flake.nix / flake.lock      # Nixビルド定義（コマンド・設定値の詳細はコメント参照）
├── firmware/                   # ビルド成果物（zmk_R.uf2, zmk_L.uf2, settings_reset.uf2）
├── config/
│   ├── cool642tb-mini.keymap   # キーマップ・behaviors・combos 定義
│   ├── cool642tb-mini.conf     # 左右共通Kconfig（ビルド時に両側へ自動マージ）
│   ├── cool642tb-mini.json     # ZMK Studio 用物理レイアウト定義
│   ├── west.yml                # ZMK fork・PMW3610ドライバ依存定義
│   └── boards/shields/cool642tb-mini/
│       ├── cool642tb-mini.dtsi          # 共通定義（kscan、matrix transform、encoder）
│       ├── cool642tb-mini_R.conf        # 右側Kconfig（PMW3610・ZMK Studio等）
│       ├── cool642tb-mini_L.conf        # 左側Kconfig
│       ├── cool642tb-mini_R.overlay     # 右側オーバーレイ（PMW3610 SPI定義）
│       ├── cool642tb-mini_L.overlay     # 左側オーバーレイ（EC11有効化）
│       ├── cool642tb-mini.zmk.yml       # shield メタデータ
│       ├── Kconfig.shield               # shield 定義（R/L）
│       └── Kconfig.defconfig            # shield 固有デフォルト（split role 等）
```

> `result/`, `result-reset/`, `zephyr/` はビルド時に生成される一時・キャッシュ領域。

## ビルド

[zmk-nix](https://github.com/lilyinstarlight/zmk-nix) を使用したNixローカルビルド。
コマンドの挙動・`flashDriveLetter` 等、詳細は `flake.nix` のコメントを参照。

```bash
# ビルド + firmware/ へのコピーを一発実行（日常はこれだけ）
nix run .#

# 個別ビルド（成果物は nix store へ出力、firmware/ は更新されない）
nix build .#firmware         # → result/zmk_R.uf2, result/zmk_L.uf2
nix build .#settings-reset   # → result/zmk.uf2

# West 依存の更新（west.yml 変更時）
nix run .#update

# フラッシュ（WSL: drvfs 経由で UF2 ブートローダーにコピー）
# ※ 実行前に `nix run .#` で firmware/ を最新化すること
nix run .#flash-win-R     # R側のみ（キーマップ変更は通常これだけで可）
nix run .#flash-win-L     # L側のみ
```

### 初回セットアップ

`zephyrDepsHash` が未更新状態で `nix build` を実行 → エラーメッセージに表示される正しいハッシュで `flake.nix` を置換 → 再ビルドで成功。詳細は [zmk-nix](https://github.com/lilyinstarlight/zmk-nix) ドキュメント参照。

### AC条件（Acceptance Criteria）

設定変更時のAC: **`nix run .#` が exit code 0 で完了し、`firmware/zmk_R.uf2`, `firmware/zmk_L.uf2`, `firmware/settings_reset.uf2` が更新されること**

## キーマップ構成

詳細（combos / behaviors / macros / tap-dances）は `config/cool642tb-mini.keymap` を参照。レイヤー一覧のみ以下に記す。

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
