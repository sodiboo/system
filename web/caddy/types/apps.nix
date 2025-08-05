{ lib, config, ... }:
{
  options.caddy.lib.types.apps = lib.mkOption {
    type = config.caddy.lib.types.module-map-declaration;
    default = { };
  };
}
