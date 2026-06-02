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
    packages = forAllSystems (system: rec {
      default = firmware;

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

      settings-reset = zmk-nix.legacyPackages.${system}.buildKeyboard {
        name = "settings-reset";
        src = firmwareSrc;
        inherit zephyrDepsHash;
        board = "seeeduino_xiao_ble";
        shield = "settings_reset";
      };

      flash = zmk-nix.packages.${system}.flash.override { inherit firmware; };

      flash-win-R = nixpkgs.legacyPackages.${system}.writeShellApplication {
        name = "zmk-uf2-flash-wsl-R";
        text = ''
          drive="''${1:-}"
          if [ -n "$drive" ] && [ "''${#drive}" -le 2 ]; then
            drive="/mnt/''${drive,,}/"
          fi

          echo "Double tap reset on the R side, waiting for UF2 drive"
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

          cp "${firmware}/zmk_R.uf2" "$uf2_path"
          sync
          echo "Flashed R side"
        '';
      };

      flash-win-L = nixpkgs.legacyPackages.${system}.writeShellApplication {
        name = "zmk-uf2-flash-wsl-L";
        text = ''
          drive="''${1:-}"
          if [ -n "$drive" ] && [ "''${#drive}" -le 2 ]; then
            drive="/mnt/''${drive,,}/"
          fi

          echo "Double tap reset on the L side, waiting for UF2 drive"
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

          cp "${firmware}/zmk_L.uf2" "$uf2_path"
          sync
          echo "Flashed L side"
        '';
      };

      update = zmk-nix.packages.${system}.update;
    });

    devShells = forAllSystems (system: {
      default = zmk-nix.devShells.${system}.default;
    });
  };
}
