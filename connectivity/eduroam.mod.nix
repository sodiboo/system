{
  nitrogen = {config, ...}: {
    sops.secrets."eduroam/id" = {};
    sops.secrets."eduroam/pass" = {};

    sops.templates.eduroam-env.content = ''
      EDUROAM_IDENTITY=${config.sops.placeholder."eduroam/id"}
      EDUROAM_PASSWORD=${config.sops.placeholder."eduroam/pass"}
    '';

    networking.networkmanager.ensureProfiles.environmentFiles = [
      config.sops.templates.eduroam-env.path
    ];
    networking.networkmanager.ensureProfiles.profiles = {
      eduroam = {
        connection = {
          id = "eduroam";
          uuid = "74c15b1e-64d6-4eb8-86fc-8b683157b497";
          type = "802-11-wireless";
        };
        "802-11-wireless" = {
          ssid = "eduroam";
          security = "802-11-wireless-security";
        };
        "802-11-wireless-security" = {
          key-mgmt = "wpa-eap";
          proto = "rsn";
          pairwise = "ccmp";
          group = "ccmp;tkip";
        };
        "802-1x" = {
          eap = "peap";
          phase2-auth = "mschapv2";
          ca-cert = "${./eduroam-chalmers.crt}";
          altsubject-matches = "DNS:eduroam.chalmers.se";
          identity = "$EDUROAM_IDENTITY";
          password = "$EDUROAM_PASSWORD";
        };
        ipv4.method = "auto";
        ipv6.method = "auto";
      };
    };
  };
}
