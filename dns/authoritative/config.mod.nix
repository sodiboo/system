{
  carbon = {
    imports = [ ./knot ];

    knot.settings = {
      server.identity = "carbon.sodi.boo";

      templates."main" = {
        storage = "zones";
        semantic-checks = true;

        records = [
          [
            "@"
            "3600"
            "SOA"
            "carbon.sodi.boo."
            "zonemaster.sodi.boo."
            "1"
            "86400"
            "7200"
            "2419200"
            "7200"
          ]
          [
            "@"
            "3600"
            "NS"
            "carbon.sodi.boo."
          ]
        ];

        notify = [ "oxygen" ];
        acl = [ "oxygen_xfr" ];

        catalog-role = "member";
        catalog-zone = "catalog.carbon.sodi.boo";
      };

      keys."oxygen.tsig.carbon.sodi.boo" = {
        algorithm = "hmac-sha256";
        secretFile = "/run/secrets/awawa";
      };

      acl."oxygen_xfr" = {
        key = [ "oxygen.tsig.carbon.sodi.boo" ];
        action = [ "transfer" ];
        protocol = [ "quic" ];
        address = [
          "10.8.0.8"
          "85.190.241.69"
          "2a02:c202:2189:7245::1"
        ];
      };

      remote."oxygen" = {
        address = [
          "10.8.0.8"
          "85.190.241.69"
          "2a02:c202:2189:7245::1"
        ];
        via = [
          "10.8.0.6"
          "95.111.204.32"
          "2a04:3541:8000:1000:d048:cfff:fef2:2e97"
        ];
        key = "oxygen.tsig.carbon.sodi.boo";
      };

      zones."sodi.boo" = {
        template = "main";

        records = [
          [
            "carbon"
            "3600"
            "A"
            "95.111.204.32"
          ]
          [
            "carbon"
            "3600"
            "AAAA"
            "2a04:3541:8000:1000:d048:cfff:fef2:2e97"
          ]

          [
            "oxygen"
            "3600"
            "A"
            "85.190.241.69"
          ]
          [
            "oxygen"
            "3600"
            "AAAA"
            "2a02:c202:2189:7245::1"
          ]
        ];
      };

      zones."gaysex.cloud" = {
        template = "main";
      };

      zones."catalog.carbon.sodi.boo" = {
        catalog-role = "generate";
        journal-content = "none";
      };

    };
  };

  oxygen = {
    imports = [ ./knot ];

    knot.settings = {
      server.identity = "oxygen.sodi.boo";

      keys."oxygen.tsig.carbon.sodi.boo" = {
        algorithm = "hmac-sha256";
        secretFile = "/run/secrets/awawa";
      };

      remote."carbon" = {
        address = [
          "10.8.0.6"
          "95.111.204.32"
          "2a04:3541:8000:1000:d048:cfff:fef2:2e97"
        ];
        via = [
          "10.8.0.8"
          "85.190.241.69"
          "2a02:c202:2189:7245::1"
        ];
        key = "oxygen.tsig.carbon.sodi.boo";
      };

      acl."carbon_notify" = {
        key = [ "oxygen.tsig.carbon.sodi.boo" ];
        action = [ "notify" ];
        protocol = [ "quic" ];
        address = [
          "10.8.0.6"
          "95.111.204.32"
          "2a04:3541:8000:1000:d048:cfff:fef2:2e97"
        ];
      };

      templates."carbon_catalog" = {
        zonefile-sync = -1;
        zonefile-load = "none";

        master = [ "carbon" ];
        acl = [ "carbon_notify" ];
      };

      zones."catalog.carbon.sodi.boo" = {
        semantic-checks = true;
        master = [ "carbon" ];
        acl = [ "carbon_notify" ];
        # zonefile-load = "none";
        # zonefile-sync = -1;

        catalog-role = "interpret";
        catalog-template = [ "carbon_catalog" ];
      };

    };
  };
}
