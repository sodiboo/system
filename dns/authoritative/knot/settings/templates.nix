{ lib, config, ... }:
{
  options.templates = lib.mkOption {
    default = { };
    type = lib.types.attrsWith {
      placeholder = "name";
      elemType = lib.types.submodule (
        { name, ... }:
        {
          imports = [ ./zone-items.nix ];
          options = {
            id = lib.mkOption {
              type = lib.types.str;
              readOnly = true;
              default = name;
            };
            records = lib.mkOption {
              type = lib.types.listOf (lib.types.listOf lib.types.str);
              default = [ ];
            };
          };

          freeformType = config.lib.types.config-section;
        }
      );
    };
  };

  config._module.render =
    knotc:
    lib.mkMerge (
      builtins.map (template: {
        main-phase = config.lib.config-directives-for-section {
          inherit knotc;
          section = "template[${template.id}]";
          options = builtins.removeAttrs template [
            "id"
            "records"
            "storage"
            "notify"
            "master"
            "ddns-master"
          ];
        };
        notify-phase = config.lib.config-directives-for-options {
          inherit knotc;
          section = "template[${template.id}]";
          options = {
            inherit (template) notify master ddns-master;
          };
        };
      }) (builtins.attrValues config.templates)
    );
}
