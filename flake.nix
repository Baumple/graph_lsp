{
  inputs = {
      nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # 👇 we have a new input!
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay, ... }: 
  flake-utils.lib.eachDefaultSystem(system: 
  let 
    overlays = [ (import rust-overlay) (final: prev: {
      gleam = prev.gleam.overrideAttrs(oldAttrs: rec {
        src = prev.fetchFromGitHub {
          owner = "gleam-lang";
          repo = "gleam";
          rev = "refs/tags/v1.4.0";
          hash = "sha256-Wo8J8cv53kNWypb5VqUlKJas+zkCHZS6mICnpn0aZoc=";
        };
        cargoDeps = oldAttrs.cargoDeps.overrideAttrs (prev.lib.const {
          name = "gleam-lang-vendor.tar.gz";
          inherit src;
          outputHash = "sha256-QuJPkzkmiFG7mcPj7X1Y0okuxrLoDeSK3FJxr7fpUJk=";
        });
      });
    }) ];
    pkgs = import nixpkgs {
      inherit system overlays;
    };
  in
  {
    devShells.default = with pkgs; mkShell {
      buildInputs = [
        rust-bin.stable.latest.default
        gleam
      ];
    };
  });
}
