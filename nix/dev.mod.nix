{ nil, ... }:
{
  universal.home-shortcut =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        cachix
        nil.packages.x86_64-linux.nil
        nurl
        nix-diff
        nix-output-monitor
        nvd
        # nix-init
      ];

      programs.direnv.enable = true;
      programs.direnv.silent = true;
      programs.direnv.nix-direnv.enable = true;
    };
}
