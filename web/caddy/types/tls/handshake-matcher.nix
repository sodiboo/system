{ lib, config, ... }:
{
  options.caddy.lib.types.tls.handshake-matcher = lib.mkOption {
    type = config.caddy.lib.types.module-map-declaration;
    default = { };
  };
}
