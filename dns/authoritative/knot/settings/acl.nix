{ lib, config, ... }:
{
  options.acl = lib.mkOption {
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
                key = lib.types.listOf lib.types.str;
                cert-key = lib.types.listOf lib.types.str;
                remote = lib.types.listOf lib.types.str;
                action = lib.types.listOf (
                  lib.types.enum [
                    "query"
                    "notify"
                    "transfer"
                    "update"
                  ]
                );
                protocol = lib.types.listOf (
                  lib.types.enum [
                    "udp"
                    "tcp"
                    "tls"
                    "quic"
                  ]
                );
                deny = lib.types.bool;
                update-type = lib.types.listOf lib.types.str;
                update-owner = lib.types.enum [
                  "key"
                  "name"
                  "zone"
                ];
                update-owner-match = lib.types.enum [
                  "sub-or-equal"
                  "equal"
                  "sub"
                  "pattern"
                ];
                update-owner-name = lib.types.listOf lib.types.str;
              };

          freeformType = config.lib.types.config-section;
        }
      );
    };
  };

  config._module.render =
    knotc:
    lib.mkMerge (
      builtins.map (acl: {
        main-phase = config.lib.config-directives-for-section {
          inherit knotc;
          section = "acl[${acl.id}]";
          options = builtins.removeAttrs acl [
            "id"
          ];
        };
      }) (builtins.attrValues config.acl)
    );
}
