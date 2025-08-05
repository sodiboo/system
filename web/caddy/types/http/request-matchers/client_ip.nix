{ lib, config, ... }:
{
  caddy.lib.types.http.request-matcher.client_ip = lib.types.submodule {
    options.ranges = lib.mkOption { type = lib.types.listOf lib.types.str; };
  };
}
