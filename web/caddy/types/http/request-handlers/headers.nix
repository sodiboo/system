{ lib, config, ... }:
{
  config.caddy.lib.types.http.request-handler.headers = lib.types.submodule {
    options.handler = lib.mkOption { type = lib.types.enum [ "headers" ]; };
    freeformType = config.caddy.lib.types.http.headers-request-handler;
  };

  # separated for reuse in reverse_proxy
  options.caddy.lib.types.http.headers-request-handler = lib.mkOption {
    type = lib.types.optionType;
  };
  config.caddy.lib.types.http.headers-request-handler = config.caddy.lib.types.sparse-submodule {
    options =
      let
        actions = {
          add = lib.mkOption { type = config.caddy.lib.types.http.headers; };
          set = lib.mkOption { type = config.caddy.lib.types.http.headers; };
          delete = lib.mkOption { type = lib.types.listOf lib.types.str; };
          replace = lib.mkOption {
            type = lib.types.attrsOf (
              lib.types.listOf (
                config.caddy.lib.types.sparse-submodule {
                  options = {
                    search = lib.mkOption { type = config.caddy.lib.types.nonempty-str; };
                    search_regexp = lib.mkOption { type = config.caddy.lib.types.nonempty-str; };
                    replace = lib.mkOption { type = config.caddy.lib.types.nonempty-str; };
                  };
                }
              )
            );
          };
        };
      in
      {
        request = actions;
        response = actions // {
          require = lib.mkOption { type = config.caddy.lib.types.http.response-matcher; };
          deferred = lib.mkOption { type = lib.types.bool; };
        };
      };
  };
}
