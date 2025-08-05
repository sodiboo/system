{ lib, config, ... }:
{
  caddy.lib.types.http.encoders.gzip = config.caddy.lib.types.sparse-submodule {
    options = {
      level = lib.mkOption { type = lib.types.ints.between 1 9; };
    };
  };

  caddy.lib.types.http.precompressed.gzip = lib.types.submodule { };
}
