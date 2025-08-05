{ lib, config, ... }:
{
  options.caddy.lib.types.http.request-matcher = lib.mkOption {
    type = config.caddy.lib.types.module-map-declaration;
    default = { };
  };
}
