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
          shellAliases = let
            conf = ''env NIX_CONFIG="warn-dirty = false"'';
            rebuild = switch: "sh -c '${builtins.concatStringsSep " && " [
              "cd /etc/nixos"
              "${conf} nix fmt -- --quiet *"
              "${conf} nix flake update"
              "git add ."
              (
                if switch
                then "sudo ${conf} nixos-rebuild switch"
                else "${conf} nixos-rebuild build"
              )
            ]}'";
          in {
            eza = "eza --long --all --icons --time-style long-iso";

            nix-shell = "nix-shell --run fish";
            nix-switch = rebuild true;
            nix-rebuild = rebuild false;
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
