{ lib, config, ... }:
{
  options.caddy.lib.types.http.request-handler = lib.mkOption {
    type = config.caddy.lib.types.tagged-union-declaration "handler";
    default = { };
  };
}
