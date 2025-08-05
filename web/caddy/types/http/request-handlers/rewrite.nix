{ lib, config, ... }:
{
  config.caddy.lib.types.http.request-handler.rewrite = lib.types.submodule {
    options.handler = lib.mkOption { type = lib.types.enum [ "rewrite" ]; };
    freeformType = config.caddy.lib.types.http.rewrite-request-handler;
  };
  # separated for reuse in reverse_proxy
  options.caddy.lib.types.http.rewrite-request-handler = lib.mkOption {
    type = lib.types.optionType;
  };
  config.caddy.lib.types.http.rewrite-request-handler = config.caddy.lib.types.sparse-submodule {
    options = {
      method = lib.mkOption { type = config.caddy.lib.types.nonempty-str; };
      uri = lib.mkOption { type = config.caddy.lib.types.nonempty-str; };

      strip_path_prefix = lib.mkOption { type = config.caddy.lib.types.nonempty-str; };
      strip_path_suffix = lib.mkOption { type = config.caddy.lib.types.nonempty-str; };

      uri_substring = lib.mkOption {
        type = lib.types.listOf (
          config.caddy.lib.types.sparse-submodule {
            options = {
              find = lib.mkOption { type = config.caddy.lib.types.nonempty-str; };
              replace = config.caddy.lib.mkRequiredOption { type = lib.types.str; };
              limit = lib.mkOption { type = lib.types.ints.positive; };
            };
          }
        );
      };

      path_regexp = lib.mkOption {
        type = lib.types.listOf (
          config.caddy.lib.types.sparse-submodule {
            options = {
              find = lib.mkOption { type = config.caddy.lib.types.nonempty-str; };
              replace = config.caddy.lib.mkRequiredOption { type = lib.types.str; };
            };
          }
        );
      };

      query =
        let
          kv = config.caddy.lib.types.sparse-submodule {
            options = {
              key = lib.mkOption { type = config.caddy.lib.types.nonempty-str; };
              val = config.caddy.lib.mkRequiredOption { type = lib.types.str; };
            };
          };
        in
        {
          rename = lib.mkOption { type = lib.types.listOf kv; };
          set = lib.mkOption { type = lib.types.listOf kv; };
          add = lib.mkOption { type = lib.types.listOf kv; };
          replace = lib.mkOption {
            type = lib.types.listOf (
              config.caddy.lib.types.sparse-submodule {
                options = {
                  key = lib.mkOption { type = config.caddy.lib.types.nonempty-str; };
                  search = lib.mkOption { type = config.caddy.lib.types.nonempty-str; };
                  search_regexp = lib.mkOption { type = config.caddy.lib.types.nonempty-str; };
                  replace = config.caddy.lib.mkRequiredOption { type = lib.types.str; };
                };
              }
            );
          };
          delete = lib.mkOption { type = lib.types.listOf lib.types.str; };
        };

    };
  };
}
