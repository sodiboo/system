{ lib, config, ... }:
{
  options.caddy.lib.types.listener-wrapper = lib.mkOption {
    type = config.caddy.lib.types.tagged-union-declaration "wrapper";
    default = { };
  };
}
