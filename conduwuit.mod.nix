{conduwuit, ...}: {
  oxygen.modules = [
    ({config, ...}: {
      networking.firewall.allowedTCPPorts = [8448];
      services.matrix-conduit = {
        enable = true;
        package = conduwuit.packages.x86_64-linux.default;
        settings.global = {
          server_name = "gaysex.cloud";
          database_backend = "rocksdb";
          max_request_size = 1024 * 1024 * 1024;
          address = "127.0.0.1";
        };
      };
    })
  ];
}
