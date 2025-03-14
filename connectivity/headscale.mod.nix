{
  oxygen.modules = [
    {
      services.headscale = {
        enable = true;
        port = 3004;
        settings = {
          server_url = "https://vpn.sodi.boo";
          dns.base_domain = "tail";

          log.level = "warn";
          logtail.enabled = false;
          metrics_listen_addr = "127.0.0.1:3005";

          prefixes.v4 = "100.64.0.0/10";
          prefixes.v6 = "fd7a:115c:a1e0::/48";

          derp.server = {
            enable = true;
            region_id = 999;
            stun_listen_addr = "0.0.0.0:3478";
          };
        };
      };

      networking.firewall.allowedUDPPorts = [3478];
    }
  ];

  universal.modules = [
    {
      services.tailscale = {
        enable = true;
        openFirewall = true;
        useRoutingFeatures = "both";
      };
    }
  ];

  iridium.modules = [
    {
      services.tailscale.extraSetFlags = ["--advertise-exit-node"];
    }
  ];
}
