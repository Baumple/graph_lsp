{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }: let 
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
  in
  {
    packages.x86_64-linux.default = pkgs.stdenv.mkDerivation rec {
        source = ./.;
        name = "Gleam Lsp";
        buildInputs = with pkgs; [
            gleam
            erlang
        ];
        buildPhase = ''gleam build'';

        installPhase = 
        ''
        mkdir -p $out/bin
        cp ./graph_lsp $out/bin
        '';
    };
  };
}
