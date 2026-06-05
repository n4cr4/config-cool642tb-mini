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

      makeWslFlash = side: uf2File: nixpkgs.legacyPackages.${system}.writeShellApplication {
        name = "zmk-uf2-flash-wsl-${side}";
        text = ''
          drive="''${1:-}"
          if [ -n "$drive" ] && [ "''${#drive}" -le 2 ]; then
            drive="/mnt/''${drive,,}/"
          fi

          echo "Double tap reset on the ${side} side, waiting for UF2 drive"
          echo -n "Scanning"
          uf2_path=""
          while [ -z "$uf2_path" ]; do
            if [ -n "$drive" ] && [ -f "''${drive}INFO_UF2.TXT" ]; then
              uf2_path="$drive"
            else
              for mnt in /mnt/*/; do
                if [ -z "$uf2_path" ] && [ -f "''${mnt}INFO_UF2.TXT" ]; then
                  uf2_path="$mnt"
                fi
              done
            fi
            [ -z "$uf2_path" ] && echo -n . && sleep 1
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
