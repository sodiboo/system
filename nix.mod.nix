{
  nix-monitored,
  extras,
  ...
}: let
  caches = {
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
    ({
      config,
      lib,
      ...
    }:
      lib.mkIf (config.networking.hostName != "iridium") {
        nix.settings = {
          substituters = ["https://cache.sodi.boo"];
          trusted-public-keys = ["sodiboo/system:N1cJgHSRSRKvlItFJDjXQBCgAhRo7hvTNw8TqyrhCUw="];
        };
      })
  ];

  iridium.modules = [
    ({config, ...}: {
      services.nix-serve = {
        enable = true;
        port = 5020;
        openFirewall = true;
        secretKeyFile = config.sops.secrets.binary-cache-secret.path;
      };
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
