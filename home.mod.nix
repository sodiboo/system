{home-manager, ...}: {
  universal = {
    config,
    lib,
    ...
  }: {
    imports = [home-manager.nixosModules.home-manager];

    options.home-shortcut = lib.mkOption {
      description = ''
        This is a shortcut to `home-manager.users.sodiboo`.

        It is only used for brevity throughout the configuration, and so that my username is not hardcoded absolutely everywhere.
      '';

      type = lib.mkOptionType {
        name = "home-manager module";
        check = _: true;
        merge = loc:
          map (def: {
            _file = def.file;
            imports = [def.value];
          });
      };
    };

    config = {
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
        imports = config.home-shortcut;
      };
    };
  };

  personal.home-shortcut = {
    lib,
    config,
    ...
  }: {
    options.systemd-fuckery = {
      auto-restart = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
      };
    };

    config = {
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
  };
}
