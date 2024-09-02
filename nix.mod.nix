{nix-monitored, ...}: let
  caches = {
    "https://sodiboo.cachix.org" = "sodiboo.cachix.org-1:OYvR3VK0IKqu+iE5T6cE7rNENoKgNQv++tkiv4oJkII=";
  };
in {
  universal.modules = [
    ({config, ...}: {
      nix.settings = {
        experimental-features = ["nix-command" "flakes"];
        substituters = builtins.attrNames caches;
        trusted-public-keys = builtins.attrValues caches;
      };
      # access-token-prelude contains:
      # access-token = github.com=$SECRET
      nix.extraOptions = ''
        !include ${config.sops.secrets.access-token-prelude.path}
      '';
      nixpkgs.overlays = [nix-monitored.overlays.default];
      nixpkgs.config.allowUnfree = true;
      nixpkgs.config.permittedInsecurePackages = [
        "jitsi-meet-1.0.8043"
      ];
      system.stateVersion = "23.11";
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
        # nix-init
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
