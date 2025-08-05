{ lib, config, ... }:
{
  caddy.lib.types.http.request-handler.reverse_proxy = config.caddy.lib.types.sparse-submodule {
    options = {
      handler = config.caddy.lib.mkRequiredOption { type = lib.types.enum [ "reverse_proxy" ]; };

      headers = lib.mkOption { type = config.caddy.lib.types.http.headers-request-handler; };
      rewrite = lib.mkOption { type = config.caddy.lib.types.http.rewrite-request-handler; };

      upstreams = lib.mkOption {
        type = lib.types.listOf (
          config.caddy.lib.types.sparse-submodule {
            options = {
              dial = lib.mkOption { type = config.caddy.lib.types.nonempty-str; };
              max_requests = lib.mkOption { type = lib.types.ints.positive; };
            };
          }
        );
      };

      handle_response = lib.mkOption {
        type = lib.types.listOf config.caddy.lib.types.http.response-handler;
      };
    };
  };
}
