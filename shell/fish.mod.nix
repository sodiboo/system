{
  universal =
    { pkgs, ... }:
    {
      programs.fish = {
        enable = true;
        interactiveShellInit = ''
          set fish_greeting

          set machines "iridium" "sodium" "nitrogen" "oxygen"
        '';
      };
      users.defaultUserShell = pkgs.fish;

      home-shortcut = {
        home.persistence."/nix/persist".files = [ ".local/share/fish/fish_history" ];

        programs = {
          fish = {
            enable = true;
            shellAliases = {
              eza = "eza --long --all --icons --time-style long-iso";
              "@" = "kitten ssh";
            };

            plugins = [
              {
                name = "fish-completions-sync";
                src = pkgs.fetchFromGitHub {
                  owner = "pfgray";
                  repo = "fish-completion-sync";
                  rev = "4f058ad2986727a5f510e757bc82cbbfca4596f0";
                  sha256 = "sha256-kHpdCQdYcpvi9EFM/uZXv93mZqlk1zCi2DRhWaDyK5g=";
                };
              }
            ];
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
    };

  personal.home-shortcut = {
    programs.fish.shellAliases = {
      nix-shell = "nix-shell --run fish";
      bwsh = "BW_SESSION=$(bw unlock --raw) fish; bw lock";
      pki-pass = "bw list items | jq -r '.[] | select(.name == \"PKI '$(hostname)'\") | .notes'";
    };
  };
}
