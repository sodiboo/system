{ lib, config, ... }:
{
  options.caddy.lib.types.settings = lib.mkOption { type = lib.types.optionType; };
  config.caddy.lib.types.settings = lib.types.submodule {
    options = {
      admin = {
        disabled = lib.mkOption { type = lib.types.bool; };
      };

      storage = lib.mkOption { type = config.caddy.lib.types.storage; };
      apps = lib.mkOption { type = config.caddy.lib.types.apps; };
    };
  };
}
