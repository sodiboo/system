{
  system ? builtins.currentSystem,
  flake ? builtins.getFlake (toString ./.),
}:

let
  pkgs = flake.inputs.nixpkgs.legacyPackages.${system};
  inherit (pkgs) lib;

  rust-bin = flake.inputs.rust-overlay.lib.mkRustBin { } pkgs;

  rust-nightly-toolchain = rust-bin.selectLatestNightlyWith (
    toolchain:
    toolchain.default.override {
      extensions = [
        "rust-analyzer"
        "rust-src"
      ];
    }
  );
in
pkgs.mkShell {
  packages = [
    # rust-nightly-toolchain
    pkgs.just
    pkgs.nixfmt
    pkgs.nixfmt-tree
    (pkgs.nix-update.overrideAttrs (
      finalAttrs: prevAttrs: {
        makeWrapperArgs = prevAttrs.makeWrapperArgs ++ [
          (lib.escapeShellArgs [
            "--prefix"
            "NIX_CONFIG"
            "\n"
            "extra-experimental-features = pipe-operators" # ugh, Nix calls this feature a different thing from Lix.
            "--run"
            "export GITHUB_TOKEN=\${GITHUB_TOKEN-$(cat /run/secrets/github-access-token)}"
          ])
        ];
      }
    ))
  ];
}
