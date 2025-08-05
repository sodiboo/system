{ lib, config, ... }:
{
  caddy.lib.types.http.request-matcher.protocol = lib.types.str;
}
