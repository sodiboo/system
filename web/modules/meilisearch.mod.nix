{
  universal =
    {
      modulesPath,
      lib,
      pkgs,
      config,
      ...
    }:
    {
      config = {
        systemd.services.meilisearch.serviceConfig = {

          ProtectSystem = "strict";
          ProtectHome = true;
          ProtectClock = true;
          ProtectHostname = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          ProtectControlGroups = true;
          PrivateTmp = true;
          PrivateMounts = true;
          PrivateUsers = true;
          PrivateDevices = true;
          RestrictRealtime = true;
          RestrictNamespaces = true;
          RestrictSUIDSGID = true;
          LockPersonality = true;
          MemoryDenyWriteExecute = true;

          ProcSubset = "pid";
          ProtectProc = "invisible";

          NoNewPrivileges = true;

          RestrictAddressFamilies = [
            # Meilisearch does not support listening on AF_UNIX sockets,
            # so we currently restrict it to only AF_INET and AF_INET6.
            "AF_INET"
            "AF_INET6"
          ];

          CapabilityBoundingSet = "";
          SystemCallArchitectures = "native";
          SystemCallFilter = [
            "@system-service"
            "~@privileged @resources"
          ];

          UMask = "0077";
        };
      };
    };
}
