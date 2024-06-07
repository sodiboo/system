{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = {nixpkgs, ...}: let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
  in {
    formatter.x86_64-linux = pkgs.alejandra;

    devShells.x86_64-linux.default = pkgs.mkShell {
      buildInputs = with pkgs; [
        pkg-config
        openssl
      ];
    };
  };
}
