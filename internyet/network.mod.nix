{
  nitrogen = {pkgs, ...}: {
    networking.nameservers = [
      "10.37.37.1"
      "fc00::1337"
    ];

    security.pki.certificateFiles = [ ./ca.crt ];

    programs.wireshark.enable = true;
    programs.wireshark.usbmon.enable = true;

    programs.wireshark.package = pkgs.wireshark;

    users.users.sodiboo.extraGroups = ["wireshark"];
  };
}