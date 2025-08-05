{ lib, config, ... }:
{
  options.caddy.lib.types.storage = lib.mkOption {
    type = config.caddy.lib.types.tagged-union-declaration "module";
    default = { };
  };
}
