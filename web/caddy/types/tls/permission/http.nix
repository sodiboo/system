{ lib, config, ... }:
{
  caddy.lib.types.tls.permission.http = lib.types.submodule {
    options = {
      module = lib.mkOption { type = lib.types.enum [ "http" ]; };
      endpoint = lib.mkOption { type = lib.types.str; };
    };
  };
}
