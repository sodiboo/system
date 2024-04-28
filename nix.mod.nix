{secrets, ...}: let
  caches = {
    # "https://niri.cachix.org" = "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964=";
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
    ({
      pkgs,
      lib,
      ...
    }: {
      home.packages = with pkgs; [
        cachix
        nil
        nurl
        nix-diff
        nh
        nix-output-monitor
        nvd
      ];

      programs.fish.shellAliases = let
        conf = ''env NIX_CONFIG="warn-dirty = false"'';
        rebuild = verb: dry: "sh -c '${builtins.concatStringsSep " && " [
          "cd /etc/nixos"
          "${conf} nix fmt -- --quiet *"
          "git add ."
          (
            if dry
            then "${conf} nh os ${verb} --update --dry ."
            else "${conf} nh os ${verb} --update ."
          )
        ]}'";
      in
        lib.mergeAttrsList (map (verb: {
          "nix.${verb}" = rebuild verb false;
          "nix+${verb}" = rebuild verb true;
        }) ["switch" "boot" "test"])
        // {
          nix-shell = "nix-shell --run fish";
        };
    })
  ];
}
