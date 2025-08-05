{ lib, config, ... }:
{
  caddy.lib.types.http.request-matcher.method = lib.types.listOf lib.types.str;
}
