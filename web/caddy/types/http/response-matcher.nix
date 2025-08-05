{ lib, config, ... }:
{
  options.caddy.lib.types.http.response-matcher = lib.mkOption {
    type = config.caddy.lib.types.module-map-declaration;
    default = { };
  };
}
