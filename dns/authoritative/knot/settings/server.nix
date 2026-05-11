{ lib, config, ... }:
{
  options.server = lib.mkOption {
    default = { };
    type = lib.types.submodule (
      { name, ... }:
      {
        options =
          builtins.mapAttrs
            (
              _: type:
              lib.mkOption {
                type = lib.types.nullOr type;
                default = null;
              }
            )
            {
              identity = lib.types.str;
              version = lib.types.str;
              nsid = lib.types.str;

              rundir = lib.types.str;
              user = lib.types.str;
              pidfile = lib.types.str;

              udp-workers = lib.types.int;
              tcp-workers = lib.types.int;
              background-workers = lib.types.int;

              async-start = lib.types.bool;
              tcp-idle-timeout = lib.types.ints.unsigned;
              tcp-io-timeout = lib.types.int;
              tcp-remote-io-timeout = lib.types.int;
              tcp-max-clients = lib.types.int;
              tcp-reuseport = lib.types.bool;
              tcp-fastopen = lib.types.bool;
              quic-max-clients = lib.types.int;
              quic-outbuf-max-size = lib.types.ints.unsigned;
              quic-idle-close-timeout = lib.types.ints.unsigned;
              remote-pool-limit = lib.types.int;
              remote-pool-timeout = lib.types.ints.unsigned;
              remote-retry-delay = lib.types.int;
              socket-affinity = lib.types.bool;
              udp-max-payload = lib.types.ints.unsigned;
              udp-max-payload-ipv4 = lib.types.ints.unsigned;
              udp-max-payload-ipv6 = lib.types.ints.unsigned;
              key-file = lib.types.str;
              cert-file = lib.types.str;
              edns-client-subnet = lib.types.bool;
              answer-rotation = lib.types.bool;
              automatic-acl = lib.types.bool;
              proxy-allowlist = lib.types.listOf lib.types.str;

              dbus-event = lib.types.listOf (
                lib.types.enum [
                  "none"
                  "running"
                  "zone-updated"
                  "keys-updated"
                  "ksk-submission"
                  "dnssec-invalid"
                ]
              );
              dbus-init-delay = lib.types.ints.unsigned;

              listen = lib.types.listOf lib.types.str;
              listen-tls = lib.types.listOf lib.types.str;
              listen-quic = lib.types.listOf lib.types.str;
            };

        freeformType = config.lib.types.config-section;
      }
    );
  };

  config._module.render = knotc: {
    main-phase = config.lib.config-directives-for-options {
      inherit knotc;
      section = "server";
      options = config.server;
    };
  };
}
