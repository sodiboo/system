{nix-index-database, ...}: {
  shared.modules = [
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

  shared.home_modules = [
    {
      programs = {
        fish = {
          enable = true;
          shellAbbrs = {
            ls = "eza";
            exa = "eza";
            tree = "eza --tree";
            cat = "bat";
          };
          shellAliases = {
            eza = "eza --long --all --icons --time-style long-iso";

            bwsh = "BW_SESSION=$(bw unlock --raw) fish; bw lock";
          };
        };

        powerline-go.enable = true;
        powerline-go.modules = [
          "ssh"
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

        bash.enable = true; # Sometimes, applications drop me into a bash shell against my will.
      };
    }
  ];
}
