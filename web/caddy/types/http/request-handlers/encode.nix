{ lib, config, ... }:
{
  caddy.lib.types.http.request-handler.encode = config.caddy.lib.types.sparse-submodule {
    options = {
      handler = config.caddy.lib.mkRequiredOption { type = lib.types.enum [ "encode" ]; };

      match = lib.mkOption { type = config.caddy.lib.types.http.response-matcher; };

      encodings = lib.mkOption { type = config.caddy.lib.types.http.encoders; };

      prefer = lib.mkOption {
        type = lib.types.listOf (
          lib.types.enum (builtins.attrNames config.caddy.lib.types.http.encoders.nestedTypes)
        );
      };

      minimum_length = lib.mkOption { type = lib.types.ints.positive; };
    };
  };
}
