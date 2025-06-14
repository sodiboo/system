{ nix-index-database, ... }:
{
  universal.imports = [
    nix-index-database.nixosModules.nix-index

    (
      { pkgs, ... }:
      {
        programs.fish = {
          enable = true;
          interactiveShellInit = ''
            set fish_greeting
            function fish_command_not_found
              , $argv
            end

            set machines "iridium" "sodium" "nitrogen" "oxygen"

            set EDITOR kak
          '';
        };
        users.defaultUserShell = pkgs.fish;

        programs.nix-index-database.comma.enable = true;
        programs.command-not-found.enable = false;
        programs.nix-index.enableFishIntegration = false;

        home-shortcut = {
          programs = {
            fish = {
              enable = true;
              shellAliases = {
                eza = "eza --long --all --icons --time-style long-iso";
                "@" = "kitten ssh";
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
        };
      }
    )
  ];

  personal.home-shortcut = {
    programs.fish.shellAliases = {
      nix-shell = "nix-shell --run fish";
      bwsh = "BW_SESSION=$(bw unlock --raw) fish; bw lock";
      pki-pass = "bw list items | jq -r '.[] | select(.name == \"PKI '$(hostname)'\") | .notes'";
    };
  };
}
