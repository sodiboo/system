{ lib, config, ... }:
{
  options.caddy.lib.types.http.encoders = lib.mkOption {
    type = config.caddy.lib.types.module-map-declaration;
    default = { };
  };

  options.caddy.lib.types.http.precompressed = lib.mkOption {
    type = config.caddy.lib.types.module-map-declaration;
    default = { };
  };
}
