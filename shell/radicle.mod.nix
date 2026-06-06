{
  personal.home-shortcut =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.radicle-node
        pkgs.radicle-tui
        pkgs.radicle-desktop
      ];

      programs.fish.shellAliases.rad = "rad-tui";
    };
}
