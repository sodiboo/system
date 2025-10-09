{
  iridium = {
    systemd.tmpfiles.settings."60-plutonium-backing-storage" = {
      "/storage/plutonium".d = {
        user = "root";
        group = "root";
        mode = "0755";
      };
    };
    containers.plutonium.bindMounts = {
      "/nix/persist" = {
        hostPath = "/storage/plutonium";
        isReadOnly = false;
      };
    };
  };

  plutonium.environment.persistence."/nix/persist".enable = true;
}
