{ lib, config, ... }:
{
  caddy.lib.types.http.request-matcher.host = lib.types.listOf lib.types.str;
}
