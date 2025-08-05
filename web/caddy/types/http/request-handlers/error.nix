{ lib, config, ... }:
{
  caddy.lib.types.http.request-handler.error = config.caddy.lib.types.sparse-submodule {
    options = {
      handler = config.caddy.lib.mkRequiredOption { type = lib.types.enum [ "error" ]; };

      error = lib.mkOption { type = config.caddy.lib.types.nonempty-str; };
      status_code = lib.mkOption { type = config.caddy.lib.types.nonempty-str; };
    };
  };
}
