{ lib, config, ... }:
{
  options.caddy.lib.types.dns.provider = lib.mkOption {
    type = config.caddy.lib.types.tagged-union-declaration "name";
    default = { };
  };
}
