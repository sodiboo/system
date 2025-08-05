{ lib, config, ... }:
{
  options.caddy.lib.types.tls.permission = lib.mkOption {
    type = config.caddy.lib.types.tagged-union-declaration "module";
    default = { };
  };
}
