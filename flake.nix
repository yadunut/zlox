{
  description = "A simple Go package";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.zig.url = "github:mitchellh/zig-overlay";

  outputs = { self, nixpkgs, flake-utils, zig }: let
    overlays = [
     # Other overlays
      (final: prev: {
        zigpkgs = zig.packages.${prev.system};
      })
    ]; in flake-utils.lib.eachDefaultSystem (system:
    let pkgs = import nixpkgs {
      inherit system;
      inherit overlays;
    }; in {
      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs; [ 
          zigpkgs.master
          zls
        ];
        };
    });
}
