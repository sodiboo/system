{ lib, config, ... }:
{
  caddy.lib.types.http.request-matcher.path = lib.types.listOf lib.types.str;
}
