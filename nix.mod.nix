{
  self,
  nix-monitored,
  elements,
  nil,
  ...
}: let
  caches = {
    # "https://nixpkgs-wayland.cachix.org" = "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA=";
  };

  garbage-collection-module = {lib, ...}: {
    programs.nh.clean = {
      enable = true;
      extraArgs = "--keep 3 --keep-since 7d";
      # this is somewhere in the middle of my commute to school.
      # and if i'm not at school, i'm likely asleep.
      dates = "Mon..Fri *-*-* 07:00:00";
    };

    nix.optimise = {
      automatic = true;
      # why is that a list?
      dates = ["Mon..Fri *-*-* 07:30:00"];
    };

    # I don't want these to be persistent or have any delay.
    # They don't need to run daily; if they miss a day, it's fine.
    # And i don't want them to ever delay until e.g. i'm at school
    # because that will impact my workflow if i want to remote in.
    systemd.timers = let
      fuck-off.timerConfig = {
        Persistent = lib.mkForce false;
        RandomizedDelaySec = lib.mkForce 0;
      };
    in {
      nh-clean = fuck-off;
      nix-optimise = fuck-off;
    };
  };
in {
  universal.modules = [
    {
      system.stateVersion = "23.11";
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
          nix-direnv = pkgs.runCommand "nix-direnv-monitored" {} ''
            cp -R ${prev.nix-direnv.override {
              # Okay, so what's happening here is that `nix-direnv` doesn't just use `nix` from PATH.
              # However, it also doesn't use `nix` from nix store. It uses both.
              # So what i'm doing here, is setting the "fallback path" to nix, being nix-monitored.
              nix = prev.nix-monitored;
            }} $out
            chmod -R +w $out
            ${
              # And then, i'm replacing the command that it uses to find nix with `false`.
              # This makes it think there's no nix in PATH, and it will use the fallback path.
              # And voila, i get nom output in direnv.
              "sed -i 's/command -v nix/false/' $out/share/nix-direnv/direnvrc"
            }
          '';
          nixmon = prev.runCommand "nixmon" {} ''
            mkdir -p $out/bin
            ln -s ${prev.nix-monitored}/bin/nix $out/bin/nixmon
          '';
        })
      ];
      environment.systemPackages = [pkgs.nixmon];
      programs.nh.enable = true;
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
        shell = pkgs.runtimeShell;
      };

      users.groups.remote-builder = {};
    })
    ({
      config,
      lib,
      ...
    }: {
      options.personal-binary-cache-url = lib.mkOption {
        type = lib.types.str;
        default = "https://cache.sodi.boo";
      };
      config =
        lib.mkIf (
          # Don't make iridium a substitute for itself. That would be silly.
          config.networking.hostName != "iridium"
        ) {
          nix.settings = {
            substituters = [config.personal-binary-cache-url];
            trusted-public-keys = ["sodiboo/system:N1cJgHSRSRKvlItFJDjXQBCgAhRo7hvTNw8TqyrhCUw="];
          };
        };
    })
  ];

  sodium.modules = [
    garbage-collection-module
    {
      personal-binary-cache-url = let
        port = toString self.nixosConfigurations.iridium.config.services.nix-serve.port;
        # sodium and iridium are on the same network, so let's not go through a hop to germany.
      in "http://iridium.lan:${port}";
    }
  ];

  personal.modules = [
    {
      # AMD gpu, basically. used for e.g. resource monitoring with btop
      nixpkgs.config.rocmSupport = true;
    }
  ];

  iridium.modules = [
    {
      users.users.remote-builder.openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBIwHeeSm7ten3Rxqj90xaBWgyRw1xYqBjKBj8nevFOD remote-builder"
      ];

      nix.settings.trusted-users = ["remote-builder"];
    }
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
    garbage-collection-module
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
        nil.packages.x86_64-linux.nil
        nurl
        nix-diff
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
