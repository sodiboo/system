{
  personal.home-shortcut =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      # note: the waybar module is sufficiently complex and versatile that i augment it
      # so, this one is more general and `programs.waybar.systemd.transient.enable` is enabled elsewhere
      # but the other modules in this directory are on by default.

      cfg = config.programs.waybar;
    in
    {
      options.programs.waybar.systemd.transient = {
        enable = lib.mkEnableOption "transient waybar";
      };

      config = lib.mkIf (cfg.systemd.transient.enable) {
        transient-session.services."waybar@" =
          let
            # Allow using attrs for settings instead of a list in order to more easily override
            settings = if builtins.isAttrs cfg.settings then lib.attrValues cfg.settings else cfg.settings;
          in
          {
            Unit = {
              Description = "Highly customizable Wayland bar for Sway and Wlroots based compositors.";
              Documentation = "https://github.com/Alexays/Waybar/wiki";
              X-Restart-Triggers =
                lib.optional (settings != [ ]) "${config.xdg.configFile."waybar/config".source}"
                ++ lib.optional (cfg.style != null) "${config.xdg.configFile."waybar/style.css".source}";
            };

            Service = {
              Environment = lib.optional cfg.systemd.enableInspect "GTK_DEBUG=interactive";
              ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR2 $MAINPID";
              ExecStart = "${cfg.package}/bin/waybar${lib.optionalString cfg.systemd.enableDebug " -l debug"}";
              KillMode = "mixed";
              Restart = "on-failure";
            };
          };
      };
    };
}
