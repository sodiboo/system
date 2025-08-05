{ lib, config, ... }:
{
  caddy.lib.types.http.request-handler.file_server = config.caddy.lib.types.sparse-submodule {
    options = {
      handler = config.caddy.lib.mkRequiredOption { type = lib.types.enum [ "file_server" ]; };

      fs = lib.mkOption { type = config.caddy.lib.types.nonempty-str; };
      root = lib.mkOption { type = config.caddy.lib.types.nonempty-str; };
      hide = lib.mkOption { type = lib.types.listOf lib.types.str; };
      index_names = lib.mkOption { type = lib.types.nonEmptyListOf lib.types.str; };
      status_code = lib.mkOption { type = config.caddy.lib.types.nonempty-str; };

      canonical_uris = lib.mkOption { type = lib.types.bool; };
      pass_thru = lib.mkOption { type = lib.types.bool; };

      precompressed = lib.mkOption { type = config.caddy.lib.types.http.precompressed; };
      precompressed_order = lib.mkOption {
        type = lib.types.listOf (
          lib.types.enum (builtins.attrNames config.caddy.lib.types.http.precompressed.nestedTypes)
        );
      };

      etag_file_extensions = lib.mkOption { type = lib.types.listOf lib.types.str; };
    };
  };
}
