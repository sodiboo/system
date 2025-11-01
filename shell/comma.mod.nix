{ nix-index-database, ... }:
{
  universal =
    { pkgs, ... }:
    {
      imports = [ nix-index-database.nixosModules.nix-index ];

      programs.nix-index-database.comma.enable = true;
      programs.command-not-found.enable = false;
      programs.nix-index.enableFishIntegration = false;

      programs.fish.interactiveShellInit = ''
        function fish_command_not_found
          command -v , &>/dev/null && , $argv
        end
      '';
    };
}
