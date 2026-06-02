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
      update = zmk-nix.packages.${system}.update;
    });

    devShells = forAllSystems (system: {
      default = zmk-nix.devShells.${system}.default;
    });
  };
}
