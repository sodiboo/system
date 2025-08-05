{ lib, config, ... }:
{
  options.caddy.lib.types.regexp = lib.mkOption {
    type = lib.types.optionType;
    readOnly = true;
    default = config.caddy.lib.types.sparse-submodule {
      options = {
        name = lib.mkOption { type = config.caddy.lib.types.nonempty-str; };
        pattern = config.caddy.lib.mkRequiredOption { type = lib.types.str; };
      };
    };
  };
}
