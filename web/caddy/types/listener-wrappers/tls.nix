{ lib, config, ... }:
{
  caddy.lib.types.listener-wrapper.tls = lib.types.submodule {
    options.wrapper = lib.mkOption { type = lib.types.enum [ "tls" ]; };
  };
}
