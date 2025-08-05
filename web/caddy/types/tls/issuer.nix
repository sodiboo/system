{ lib, config, ... }:
{
  options.caddy.lib.types.tls.issuer = lib.mkOption {
    type = config.caddy.lib.types.tagged-union-declaration "module";
    default = { };
  };
}
