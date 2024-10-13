{
  self,
  nix-monitored,
  elements,
  ...
}: let
  caches = {
    # "https://nixpkgs-wayland.cachix.org" = "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA=";
  };
in {
  universal.modules = [
    {
      system.stateVersion = "23.11";
      system.configurationRevision = self.rev or null;
      nixpkgs.config.allowUnfree = true;
      nix.settings.experimental-features = ["nix-command" "flakes"];
    }
    ({config, ...}: {
      nix.settings = {
        substituters = builtins.attrNames caches;
        trusted-public-keys = builtins.attrValues caches;
      };
      # access-token-prelude contains:
      # access-token = github.com=$SECRET
      nix.extraOptions = ''
        !include ${config.sops.secrets.access-token-prelude.path}
      '';
    })
    ({pkgs, ...}: {
      nixpkgs.overlays = [
        nix-monitored.overlays.default
        (final: prev: {
          nix-monitored = prev.nix-monitored.override {
            # I find the notifications annoying.
            withNotify = false;
          };
        })
        (final: prev: {
          nixos-rebuild = prev.nixos-rebuild.override {
            nix = prev.nix-monitored;
          };
          nix-direnv = prev.nix-direnv.override {
            nix = prev.nix-monitored;
          };
          nixmon = prev.runCommand "nixmon" {} ''
            mkdir -p $out/bin
            ln -s ${prev.nix-monitored}/bin/nix $out/bin/nixmon
          '';
        })
      ];
      environment.systemPackages = [pkgs.nixmon];
    })
    ({
      config,
      pkgs,
      lib,
      ...
    }: {
      programs.ssh.extraConfig = ''
        ${builtins.concatStringsSep "" (lib.mapAttrsToList (name: n: ''
            Host ${name}
              HostName ${name}.wg
              User remote-builder
              IdentityFile ${config.sops.secrets.remote-build-ssh-id.path}
          '')
          elements)}
      '';

      users.users.remote-builder = {
        isSystemUser = true;
        group = "remote-builder";
        description = "trusted remote builder user";
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBIwHeeSm7ten3Rxqj90xaBWgyRw1xYqBjKBj8nevFOD remote-builder"
        ];
        shell = pkgs.runtimeShell;
      };

      users.groups.remote-builder = {};

      nix.settings.trusted-users = ["remote-builder"];
    })
    ({
      config,
      lib,
      ...
    }:
      lib.mkIf (
        # Don't make iridium a substitute for itself. That would be silly.
        config.networking.hostName != "iridium"
      ) {
        nix.settings = {
          substituters = ["https://cache.sodi.boo"];
          trusted-public-keys = ["sodiboo/system:N1cJgHSRSRKvlItFJDjXQBCgAhRo7hvTNw8TqyrhCUw="];
        };
      })
  ];

  iridium.modules = [
    ({
      config,
      pkgs,
      lib,
      ...
    }: {
      # This is publicly served from https://cache.sodi.boo
      # That's proxied through oxygen from nginx.
      services.nix-serve = {
        enable = true;
        port = 5020;
        openFirewall = true;
        secretKeyFile = config.sops.secrets.binary-cache-secret.path;
      };

      systemd.timers."auto-update-rebuild" = {
        wantedBy = ["timers.target"];
        timerConfig = {
          OnBootSec = "5m";
          OnUnitInactiveSec = "1h";
          Unit = "auto-update-rebuild.service";
        };
      };

      systemd.services."auto-update-rebuild" = {
        script = ''
          mkdir -p /tmp/auto-update-rebuild && cd /tmp/auto-update-rebuild

          export PATH=${lib.makeBinPath (with pkgs; [nix git coreutils])}

          nix build github:sodiboo/system#all-systems --recreate-lock-file --no-write-lock-file
        '';

        serviceConfig = {
          Restart = "on-failure";
          RestartSec = "15m";
          Type = "oneshot";
        };
      };
    })
  ];

  nitrogen.modules = [
    ({config, ...}: {
      nix.distributedBuilds = true;
      nix.buildMachines = [
        {
          hostName = "iridium";
          system = "x86_64-linux";

          maxJobs = 4;
        }
      ];
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
