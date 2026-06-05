{
  description = "cool642tb-mini ZMK firmware";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    zmk-nix = {
      url = "github:lilyinstarlight/zmk-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, zmk-nix }: let
    forAllSystems = nixpkgs.lib.genAttrs (nixpkgs.lib.attrNames zmk-nix.packages);

    firmwareSrc = nixpkgs.lib.sourceFilesBySuffices self [
      ".board" ".cmake" ".conf" ".defconfig"
      ".dts" ".dtsi" ".json" ".keymap"
      ".overlay" ".shield" ".yml" "_defconfig"
    ];

    zephyrDepsHash = "sha256-bPVMxEpyodfr2/emynW1a+69BsY+rKuUxRu+2IxINpU=";

    # XIAO BLE ブートローダーが Windows 側で割り当てられるドライブレター。
    # 環境(Cドライブサイズ、他のUSB挿さってる等)で変わりうるので1箇所で一元管理。
    # 変わったらこの値を書き換えるだけで flash-win-R/L 両方に反映される。
    flashDriveLetter = "D";
  in {
    packages = forAllSystems (system: let
      firmware = zmk-nix.legacyPackages.${system}.buildSplitKeyboard {
        name = "firmware";
        src = firmwareSrc;
        inherit zephyrDepsHash;

        board = "seeeduino_xiao_ble";
        shield = "cool642tb-mini_%PART%";
        parts = [ "R" "L" ];
        centralPart = "R";
        enableZmkStudio = true;

        meta = {
          description = "cool642tb-mini ZMK firmware";
          license = nixpkgs.lib.licenses.mit;
          platforms = nixpkgs.lib.platforms.all;
        };
      };

      makeWslFlash = side: uf2File:
        let
          # flashDriveLetter はこの let の外側で定義済み(クロージャ参照)
          driveLetterLower = nixpkgs.lib.toLower flashDriveLetter;
        in
        nixpkgs.legacyPackages.${system}.writeShellApplication {
        name = "zmk-uf2-flash-wsl-${side}";
        text = ''
          # drvfs 自動マウント(WSL2 は起動後のホットプラグ USB を /mnt/<letter> に
          # 自動マウントしないため、XIAO BLE のブートローダーを認識させるには
          # 手動で mount -t drvfs する必要がある)

          # ドライブレター(環境変更時は flake.nix の flashDriveLetter を書き換える)
          drive_letter="${flashDriveLetter}:"
          drive="/mnt/${driveLetterLower}/"
          drvfs_opts="metadata,uid=1000,gid=1000,umask=22"

          # drvfs マウントを試行:
          # - 既に UF2 が見えていればスキップ
          # - 古い壊れたマウント(デバイス消失後のゴースト)は umount して再マウント
          # - 未マウントなら新規マウント
          ensure_drvfs_mount() {
            if [ -f "''${drive}INFO_UF2.TXT" ]; then return 0; fi

            echo ""
            echo "UF2 drive not visible at ''${drive}"
            echo "Attempting drvfs mount of ''${drive_letter} (sudo required)..."

            if [ ! -d "$drive" ]; then
              sudo mkdir -p "$drive" || { echo "mkdir failed"; return 1; }
            fi

            # 古い壊れたマウントを検出・整理
            if mountpoint -q "$drive" 2>/dev/null; then
              if ! ls "$drive" >/dev/null 2>&1; then
                echo "Stale mountpoint detected at ''${drive}, unmounting..."
                sudo umount "$drive" 2>/dev/null || true
                sleep 1
              else
                # アクセス可能だが UF2 ではない(別デバイス?) → 何もしない
                return 0
              fi
            fi

            sudo mount -t drvfs "$drive_letter" "$drive" -o "$drvfs_opts" \
              || { echo "mount failed (is the XIAO BLE in bootloader mode on Windows side?)"; return 1; }
          }

          echo "Double tap reset on the ${side} side, waiting for UF2 drive at ''${drive_letter}"
          echo -n "Scanning"
          uf2_path=""
          attempt=0
          mount_count=0
          max_mounts=3
          next_mount_attempt=5  # 初回マウント試行は5秒後
          while [ -z "$uf2_path" ]; do
            # 指定レターを優先チェック
            if [ -f "''${drive}INFO_UF2.TXT" ]; then
              uf2_path="$drive"
            else
              # 他の /mnt/*/ に既にマウント済みの UF2 がないかスキャン
              # (前回手動マウント時など)
              for mnt in /mnt/*/; do
                if [ -z "$uf2_path" ] && [ -f "''${mnt}INFO_UF2.TXT" ]; then
                  uf2_path="$mnt"
                fi
              done
            fi

            if [ -z "$uf2_path" ]; then
              attempt=$((attempt + 1))
              # 定期的に drvfs マウントを試行(最大 max_mounts 回)
              if [ "$mount_count" -lt "$max_mounts" ] && [ "$attempt" -ge "$next_mount_attempt" ]; then
                ensure_drvfs_mount || true
                mount_count=$((mount_count + 1))
                next_mount_attempt=$((attempt + 10))  # 次回は10秒後
              fi
              echo -n .
              sleep 1
            fi
          done
          echo ""
          echo "Found UF2 drive at ''${uf2_path}"

          cp "${firmware}/${uf2File}" "$uf2_path"
          sync
          echo "Flashed ${side} side"
        '';
      };
    in rec {
      default = firmware;

      inherit firmware;

      settings-reset = zmk-nix.legacyPackages.${system}.buildKeyboard {
        name = "settings-reset";
        src = firmwareSrc;
        inherit zephyrDepsHash;
        board = "seeeduino_xiao_ble";
        shield = "settings_reset";
      };

      flash = zmk-nix.packages.${system}.flash.override { inherit firmware; };

      flash-win-R = makeWslFlash "R" "zmk_R.uf2";
      flash-win-L = makeWslFlash "L" "zmk_L.uf2";

      # `nix run .#copy-artifacts` でビルド成果物を firmware/ へコピー
      copy-artifacts = nixpkgs.legacyPackages.${system}.writeShellApplication {
        name = "copy-firmware-to-repo";
        text = ''
          repo_root="$(pwd)"
          out_dir="$repo_root/firmware"
          mkdir -p "$out_dir"

          src_default="${firmware}"
          src_reset="${settings-reset}"

          install -m 0644 "$src_default/zmk_R.uf2" "$out_dir/zmk_R.uf2"
          install -m 0644 "$src_default/zmk_L.uf2" "$out_dir/zmk_L.uf2"
          install -m 0644 "$src_reset/zmk.uf2"    "$out_dir/settings_reset.uf2"

          echo "Copied firmware artifacts to $out_dir/"
          ls -la "$out_dir/"
        '';
      };

      update = zmk-nix.packages.${system}.update;
    });

    devShells = forAllSystems (system: {
      default = zmk-nix.devShells.${system}.default;
    });
  };
}
