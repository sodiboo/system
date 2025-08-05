{ lib, config, ... }:
{
  options.caddy.lib.types.http.response-handler = lib.mkOption { type = lib.types.optionType; };
  config.caddy.lib.types.http.response-handler = config.caddy.lib.types.sparse-submodule {
    options = {
      match = lib.mkOption { type = config.caddy.lib.types.http.response-matcher; };
      status_code = lib.mkOption { type = config.caddy.lib.types.nonempty-str; };
      routes = lib.mkOption { type = lib.types.listOf config.caddy.lib.types.http.route; };
    };
  };
}
