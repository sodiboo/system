inputs: {
  sodium =
    { lib, pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.bs-manager
        pkgs.lighthouse-steamvr
      ];

      # TODO: power off after monado powers off?
      # need on a timeout though. not just `bindsTo = ["monado.service"];`
      systemd.user.services.lighthouse-power = {
        wantedBy = [ "monado.service" ];

        unitConfig.ConditionUser = "!root";

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${lib.getExe pkgs.lighthouse-steamvr} -vv --state on";
          ExecStop = "${lib.getExe pkgs.lighthouse-steamvr} -vv --state off";
        };
      };

      systemd.user.services.wayvr = {
        description = "wayvr";

        requires = [ "monado.socket" ];

        wantedBy = [ "monado.service" ];
        bindsTo = [ "monado.service" ];

        unitConfig.ConditionUser = "!root";

        serviceConfig.ExecStart = lib.getExe pkgs.wayvr;
      };
    };
}
