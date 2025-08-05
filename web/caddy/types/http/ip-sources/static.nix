{ lib, config, ... }:
{
  config.caddy.lib.types.http.ip-source.static = lib.types.submodule {
    options = {
      source = lib.mkOption { type = lib.types.enum [ "static" ]; };

      ranges = lib.mkOption { type = lib.types.listOf lib.types.str; };
    };
  };
}
