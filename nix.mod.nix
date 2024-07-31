let
  caches = {
    # "https://niri.cachix.org" = "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964=";
  };
in {
  universal.modules = [
    ({config, ...}: {
      nix = {
        settings = {
          experimental-features = ["nix-command" "flakes"];
          substituters = builtins.attrNames caches;
          trusted-public-keys = builtins.attrValues caches;
        };
        package = pkgs.lix;
        # access-token-prelude contains:
        # access-token = github.com=$SECRET
        extraOptions = ''
          !include ${config.sops.secrets.access-token-prelude.path}
        '';
      };
      nixpkgs.config.allowUnfree = true;
      system.stateVersion = "23.11";

      networking.firewall.allowedUDPPorts = [25565 25577];
      networking.firewall.allowedTCPPorts = [25565 25577];
    })
  ];
  universal.home_modules = [
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
        nix-init
      ];

      programs.fish.shellAliases = let
        conf = ''env NIX_CONFIG="warn-dirty = false"'';
        rebuild = verb: dry: "fish -c '${builtins.concatStringsSep " && " [
          "cd /etc/nixos"
          "${conf} nix fmt -- --quiet *"
          "${conf} nix flake update"
          "git add ."
          (
            if dry
            then "${conf} nh os ${verb} --dry ."
            else "${conf} nh os ${verb} ."
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
