{ lib, config, ... }:
{
  caddy.lib.types.http.response-matcher.headers = config.caddy.lib.types.http.headers;
}
