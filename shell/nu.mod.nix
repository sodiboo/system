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

          # Nushell doesn't support my preferred date format in ANY of its english locales.
          #
          # I require:
          #   (0 | into datetime | format date '%x %X%.3f') == "1970-01-01 00:00:00.000"
          # See: https://gist.github.com/sodiboo/8e63cda36159474c830f2d409dc02f5e
          # The only acceptable presets are `wae_CH` and `si_LK`.
          #
          # Custom locales are normally a thing, but Nushell doesn't support them :(
          # But i don't wanna set either of those foreign locales as my systemwide,
          # because their month names are not in a native language of mine:
          #   in wae_CH: (2025-02-14 | format date '%B') == "Hornig" # <-- haha valentine's day is hornig
          #
          # So i'll use this environment variable, intended for unit testing:
          # https://github.com/nushell/nushell/blob/9b51c9be7651cd2e05a84c174781ba328c856019/crates/nu-command/src/strings/format/date.rs#L109
          #
          # Sure. `%B` in Nushell returns semi-gibberish then. But i can live with that.
          extraConfig = ''
            $env.NU_TEST_LOCALE_OVERRIDE = "wae_CH"
          '';
        };
      };
    };
}
