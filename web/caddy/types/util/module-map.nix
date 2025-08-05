{ lib, config, ... }:
let
  make-module-map =
    modules:
    lib.mkOptionType {
      name = "module-map";
      description = "module map";
      descriptionClass = "noun";

      check = builtins.isAttrs;
      merge =
        (config.caddy.lib.types.sparse-submodule {
          options = builtins.mapAttrs (_: type: lib.mkOption { inherit type; }) modules;
        }).merge;

      getSubOptions =
        prefix:
        builtins.mapAttrs (
          name: type:
          lib.mkOption {
            inherit type;
            loc = prefix ++ [ name ];
          }
        ) modules;

      nestedTypes = modules;
    };

  module-map-declaration = lib.mkOptionType {
    name = "module-map-declaration";
    description = "attrs of (option type)";
    descriptionClass = "composite";

    check = builtins.isAttrs;
    merge = loc: defs: make-module-map ((lib.types.attrsOf lib.types.optionType).merge loc defs);
  };
in
{
  options.caddy.lib.types.module-map-declaration = lib.mkOption {
    type = lib.types.optionType;
    readOnly = true;
    default = module-map-declaration;
  };
}
