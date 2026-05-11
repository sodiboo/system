{ lib, config, ... }:
{
  options.remote = lib.mkOption {
    default = { };
    type = lib.types.attrsWith {
      placeholder = "id";
      elemType = lib.types.submodule (
        { name, ... }:
        {
          options = {
            id = lib.mkOption {
              type = lib.types.str;
              readOnly = true;
              default = name;
            };
          }
          //
            builtins.mapAttrs
              (
                _: type:
                lib.mkOption {
                  type = lib.types.nullOr type;
                  default = null;
                }
              )
              {
                address = lib.types.listOf lib.types.str;
                via = lib.types.listOf lib.types.str;
                quic = lib.types.bool;
                tls = lib.types.bool;
                key = lib.types.str;
                cert-key = lib.types.listOf lib.types.str;
                block-notify-after-transfer = lib.types.bool;
                no-edns = lib.types.bool;
                automatic-acl = lib.types.bool;
              };

          freeformType = config.lib.types.config-section;
        }
      );
    };
  };

  config._module.render =
    knotc:
    lib.mkMerge (
      builtins.map (remote: {
        main-phase = lib.mkMerge [
          (config.lib.config-directives-for-section {
            inherit knotc;
            section = "remote[${remote.id}]";
            options = builtins.removeAttrs remote [
              "id"
            ];
          })
          (config.lib.config-directives-for-section {
            inherit knotc;
            section = "remotes[g${remote.id}]";
            options = {
              remote = remote.id;
            };
          })
        ];
      }) (builtins.attrValues config.remote)
    );
}
