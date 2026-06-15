# config-cool642tb-mini

cool642tb_mini専用のZMK firmware設定リポジトリ。forkしてから使用してください。

ビルド・フラッシュ手順やディレクトリ構造の詳細は [AGENTS.md](./AGENTS.md) を参照。

## ハードウェア概要

| パーツ               | 種別                                        |
| -------------------- | ------------------------------------------- |
| MCU                  | Seeeduino XIAO BLE（左右各1）               |
| キーマトリクス       | 11col x 4row、col2rowダイオード             |
| トラックボール       | PMW3610（右側のみ、SPI接続）                |
| ロータリーエンコーダ | EC11（左側のみ、24 steps）                  |
| 通信                 | BLE スプリット（右=Central、左=Peripheral） |

## クイックスタート

```bash
# ビルド + firmware/ へのコピー（日常はこれだけ）
nix run .#

# フラッシュ（WSL環境・XIAO BLEをブートローダーモードへ）
nix run .#flash-win-R     # R側
nix run .#flash-win-L     # L側
```
