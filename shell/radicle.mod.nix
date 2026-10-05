{
  personal = {
    # private repositories are insecure.
    # https://radicle.dev/2026/09/23/disclosure-of-vulnerability-in-network-protocol
    # i don't use this for private repositories, it's fine
    nixpkgs.config.permittedInsecurePackages = [
      "radicle-node-1.10.3"
    ];

    home-shortcut =
      { pkgs, ... }:
      {

        home.packages = [
          pkgs.radicle-node
          pkgs.radicle-tui
          pkgs.radicle-desktop
        ];

        programs.fish.shellAliases.rad = "rad-tui";
      };
  };
}
