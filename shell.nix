{ pkgs ? import <nixpkgs> { overlays = [(import ./gleam_overlay.nix)]; }} :
pkgs.mkShell {
  buildInputs = with pkgs; [
    gleam
    rebar
  ];
}
