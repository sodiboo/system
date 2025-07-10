{
  personal.home-shortcut =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      cfg = config.transient-session;
    in
    {
      options.transient-session = {
        target-stem = lib.mkOption {
          type = lib.types.str;
          default = "transient-session";
        };
        target = lib.mkOption {
          type = lib.types.str;
          readOnly = true;
          default = "${cfg.target-stem}@.target";
        };

        services = lib.mkOption {
          type = lib.types.attrsOf lib.types.raw;
        };
      };

      config = {
        systemd.user.targets."${cfg.target-stem}@" = {
          Unit.Description = "transient session target on %i";
        };

        systemd.user.services = builtins.mapAttrs (
          name:
          assert lib.hasSuffix "@" name;
          unit:
          lib.mkMerge [
            {
              Unit.PartOf = [ cfg.target ];
              Unit.After = [ cfg.target ];
              Install.WantedBy = [ cfg.target ];
              Service.EnvironmentFile = "%t/transient-session/%i.env";
            }
            unit
          ]
        ) cfg.services;
      };
    }

  ;
}
