{
  system ? builtins.currentSystem,
  flake ? builtins.getFlake (toString ./.),
}:

let
  pkgs = flake.inputs.nixpkgs.legacyPackages.${system};
in
pkgs.mkShell {
  packages = [
    pkgs.just
    flake.formatter.${system}
  ];
}
