{ lib, config, ... }:
{
  options.caddy.lib.types.http.route = lib.mkOption { type = lib.types.optionType; };
  config.caddy.lib.types.http.route = config.caddy.lib.types.sparse-submodule {
    options = {
      group = lib.mkOption { type = config.caddy.lib.types.nonempty-str; };
      match = lib.mkOption { type = lib.types.listOf config.caddy.lib.types.http.request-matcher; };
      handle = lib.mkOption { type = lib.types.listOf config.caddy.lib.types.http.request-handler; };
      terminal = lib.mkOption { type = lib.types.bool; };
    };
  };
}
