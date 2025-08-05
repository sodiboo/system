{ lib, config, ... }:
{
  caddy.lib.types.tls.handshake-matcher.remote_ip = lib.types.submodule {
    options = {
      ranges = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };
      not_ranges = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };
    };
  };
}
