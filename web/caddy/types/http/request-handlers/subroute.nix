{ lib, config, ... }:
{
  caddy.lib.types.http.request-handler.subroute = config.caddy.lib.types.sparse-submodule {
    options = {
      handler = config.caddy.lib.mkRequiredOption { type = lib.types.enum [ "subroute" ]; };

      routes = lib.mkOption { type = lib.types.listOf config.caddy.lib.types.http.route; };
      errors.routes = lib.mkOption { type = lib.types.listOf config.caddy.lib.types.http.route; };
    };
  };
}
