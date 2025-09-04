{
  universal =
    { pkgs, ... }:
    {
      nix.package = pkgs.lix;
      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
}
