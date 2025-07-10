{
  personal.home-shortcut =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      check-wayland-interface = pkgs.writeShellScript "check-wayland-interface" ''
        ${lib.getExe' pkgs.wayland-utils "wayland-info"} -i "$1" | grep -q "$1"
      '';
    in
    {
      transient-session.services."gammastep@" = {
        Service = {
          # gamma isn't exposed in a nested session, so we only run this if the interface is available.
          ExecCondition = "${check-wayland-interface} zwlr_gamma_control_manager_v1";
          ExecStart = "${lib.getExe pkgs.gammastep} -l 59:11"; # lol, doxxed
        };
      };
    };
}
