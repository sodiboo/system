{
  oxygen =
    {
      lib,
      config,
      ...
    }:
    {
      reverse-proxy."gaysex.cloud".locations."/_matrix".localhost.port =
        config.services.continuwuity.settings.global.port;
      reverse-proxy."gaysex.cloud".extra-public-ports = [ 8448 ];
      networking.firewall.allowedTCPPorts = [ 8448 ];

      services.continuwuity = {
        enable = false;
        settings.global = {
          server_name = "gaysex.cloud";
          max_request_size = 1024 * 1024 * 1024;
          address = "127.0.0.1";
          port = 6167;
        };
      };
    };
}
