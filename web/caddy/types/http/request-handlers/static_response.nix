{ lib, config, ... }:
{
  caddy.lib.types.http.request-handler.static_response = config.caddy.lib.types.sparse-submodule {
    options = {
      handler = config.caddy.lib.mkRequiredOption { type = lib.types.enum [ "static_response" ]; };

      status_code = lib.mkOption { type = config.caddy.lib.types.nonempty-str; };

      headers = lib.mkOption { type = config.caddy.lib.types.http.headers; };

      body = lib.mkOption { type = config.caddy.lib.types.nonempty-str; };

      close = lib.mkOption { type = lib.types.bool; };
      abort = lib.mkOption { type = lib.types.bool; };
    };
  };
}
