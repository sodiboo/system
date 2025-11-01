{
  universal =
    { lib, pkgs, ... }:
    {
      environment.shells = [
        "/run/current-system/sw/bin/nu"
        (lib.getExe pkgs.nushell)
      ];

      environment.systemPackages = [ pkgs.nushell ];

      # users.defaultUserShell = pkgs.nushell;

      home-shortcut = {
        programs.nushell = {
          enable = true;
          shellAliases = {
            nix-shell = "nix-shell --run nu";
            eza = "eza --long --all --icons --time-style long-iso";
            "@" = "kitten ssh";
          };
        };
      };
    };
}
