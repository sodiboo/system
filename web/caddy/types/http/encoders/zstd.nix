{ lib, config, ... }:
{
  caddy.lib.types.http.encoders.zstd = config.caddy.lib.types.sparse-submodule {
    options = {
      level = lib.mkOption {
        type = lib.types.enum [
          "fastest"
          "default"
          "better"
          "best"
        ];
      };
    };
  };

  caddy.lib.types.http.precompressed.zstd = lib.types.submodule { };
}
