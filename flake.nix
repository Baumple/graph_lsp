{
  description = "My gleam application";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nix-gleam.url = "github:arnarg/nix-gleam";

  outputs =
    { self
    , nixpkgs
    , flake-utils
    , nix-gleam
    ,
    }: 
    (
      flake-utils.lib.eachDefaultSystem
        (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              nix-gleam.overlays.default
            ];
          };
        in
        {
          packages.default = pkgs.buildGleamApplication {
            src = ./.;
          };
          devShells.default = pkgs.mkShell {
            name = "graph_lsp";
            buildInputs = [
              self.packages.${system}.default
            ];
          };
        })
    );
}
