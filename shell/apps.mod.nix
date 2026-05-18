inputs: {
  universal.home-shortcut =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        fastfetch
        fm-go
        dig
        whois
        libqalculate
      ];

      programs = {
        btop.enable = true;
        btop.package = pkgs.btop-rocm;
        btop.settings.theme_background = false;
      };
    };
}
