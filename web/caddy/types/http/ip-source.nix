{ lib, config, ... }:
{
  options.caddy.lib.types.http.ip-source = lib.mkOption {
    type = config.caddy.lib.types.tagged-union-declaration "source";
    default = { };
  };
}
