{ lib, config, ... }:
{
  caddy.lib.types.listener-wrapper.http_redirect = config.caddy.lib.types.sparse-submodule {
    options = {
      wrapper = config.caddy.lib.mkRequiredOption { type = lib.types.enum [ "http_redirect" ]; };
      max_header_bytes = lib.mkOption { type = lib.types.ints.positive; };
    };
  };
}
