{ lib, config, ... }:
{
  options.caddy.lib.types.tls.certificates = lib.mkOption {
    type = config.caddy.lib.types.module-map-declaration;
    default = { };
  };
}
