let
  config = name: system: additional: {
    inherit name;
    value = {
      inherit system;
      modules =
        [
          {
            networking.hostName = name;
            nixpkgs.hostPlatform = system;
          }
        ]
        ++ additional;
    };
  };

  fs = path: fsType: device: {fileSystems.${path} = {inherit device fsType;};};
  swap = device: {swapDevices = [{inherit device;}];};

  cpu = brand: {hardware.cpu.${brand}.updateMicrocode = true;};
in
  {
    shared.modules = [
      ({lib, ...}: {
        hardware.enableRedistributableFirmware = true;
        networking.useDHCP = lib.mkDefault true;
      })
    ];
  }
  // builtins.listToAttrs [
    (config "lithium" "x86_64-linux" [
      (cpu "intel")
      (fs "/" "ext4" "/dev/disk/by-uuid/64d05a5c-e962-4fb4-9c16-9185dcff2dad")
      (fs "/boot" "vfat" "/dev/disk/by-uuid/FC03-65D6")
      (swap "/dev/disk/by-uuid/4c073557-45f2-43f3-8c77-c5254917c2de")
      {
        # Not sure where these belong, or what they do. Just put here for now. TODO: cleanup.
        boot.initrd.availableKernelModules = ["xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod"];
        boot.initrd.kernelModules = [];
        boot.kernelModules = ["kvm-intel"];
        boot.extraModulePackages = [];
      }
    ])
    # TODO: sodium
  ]
