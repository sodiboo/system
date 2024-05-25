{home-manager, ...}: {
  universal.modules = [
    home-manager.nixosModules.home-manager
    ({config, ...}: {
      users.users.sodiboo = {
        isNormalUser = true;
        description = "sodiboo";
        extraGroups = ["wheel"];
      };

      home-manager.backupFileExtension = "bak";
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.sodiboo = {
        home.username = "sodiboo";
        home.homeDirectory = "/home/sodiboo";

        home.stateVersion = "22.11";
        imports = config._module.args.home_modules;
      };
    })
  ];

  personal.home_modules = [
    ({
      lib,
      config,
      ...
    }: {
      options.systemd-fuckery = {
        auto-restart = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
        };

        start-with-niri = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
        };
      };

      config = {
        systemd.user.services = builtins.listToAttrs (map (name: {
            inherit name;
            value = {
              Unit.After = ["niri.service"];
              Install.WantedBy = ["niri.service"];
            };
          })
          config.systemd-fuckery.start-with-niri);

        home.activation.restartSystemdFuckery = let
          ensureRuntimeDir = "XDG_RUNTIME_DIR=\${XDG_RUNTIME_DIR:-/run/user/$(id -u)}";

          systemctl = "env ${ensureRuntimeDir} ${config.systemd.user.systemctlPath}";

          each = f: builtins.concatStringsSep "\n" (map f config.systemd-fuckery.auto-restart);
        in
          lib.mkIf (config.systemd-fuckery.auto-restart != []) (
            lib.hm.dag.entryAfter ["reloadSystemd"] ''
              systemdStatus=$(${systemctl} --user is-system-running 2>&1 || true)

              if [[ $systemdStatus == 'running' || $systemdStatus == 'degraded' ]]; then
                ${each (unit: ''
                run ${systemctl} --user try-restart ${unit}.service
              '')}
              else
                echo "User systemd daemon not running. Skipping reload."
              fi
            ''
          );
      };
    })
  ];
}
