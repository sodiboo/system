{secrets, ...}: let
  caches = {
    "https://niri.cachix.org" = "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964=";
  };
in {
  shared.modules = [
    {
      nix.settings = {
        access-tokens = ["github.com=${secrets.github-token}"];
        experimental-features = ["nix-command" "flakes"];
        substituters = builtins.attrNames caches;
        trusted-public-keys = builtins.attrValues caches;
      };
      nixpkgs.config.allowUnfree = true;
      system.stateVersion = "23.11";
    }
  ];
  shared.home_modules = [
    ({pkgs, ...}: {
      home.packages = with pkgs; [
        cachix
        nil
      ];
    })
  ];
}
