{nix-index-database, ...}: {
  universal.modules = [
    nix-index-database.nixosModules.nix-index

    ({pkgs, ...}: {
      programs.fish = {
        enable = true;
        interactiveShellInit = ''
          set fish_greeting
          function fish_command_not_found
            , $argv
          end

          set EDITOR kak
        '';
      };
      users.defaultUserShell = pkgs.fish;

      programs.nix-index-database.comma.enable = true;
      programs.command-not-found.enable = false;
      programs.nix-index.enableFishIntegration = false;
    })
  ];

  universal.home_modules = [
    {
      programs = {
        fish = {
          enable = true;
          shellAliases = {
            eza = "eza --long --all --icons --time-style long-iso";
          };
        };

        powerline-go = {
          enable = true;
          settings.hostname-only-if-ssh = true;
          modules = [
            "host"
            "cwd"
            "perms"
            "git"
            "hg"
            "nix-shell"
            "jobs"
            # "duration" # not working
            "exit"
            "root"
          ];
        };

        bash.enable = true; # Sometimes, applications drop me into a bash shell against my will.
      };
    }
  ];

  personal.home_modules = [
    {
      programs.fish.shellAliases = {
        bwsh = "BW_SESSION=$(bw unlock --raw) fish; bw lock";
        pki-pass = "bw list items | jq -r '.[] | select(.name == \"PKI '$(hostname)'\") | .notes'";
      };
    }
  ];
}
