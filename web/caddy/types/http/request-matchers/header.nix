{ lib, config, ... }:
{
  caddy.lib.types.http.request-matcher.header = config.caddy.lib.types.http.headers;
}
