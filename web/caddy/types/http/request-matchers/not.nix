{ lib, config, ... }:
{
  caddy.lib.types.http.request-matcher.not =
    lib.types.listOf config.caddy.lib.types.http.request-matcher;
}
