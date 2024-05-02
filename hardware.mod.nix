{nixos-hardware, ...}: let
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

  filesystem = fsType: path: device: options: {
    fileSystems.${path} =
      {inherit device fsType;}
      // (
        if options == null
        then {}
        else {inherit options;}
      );
  };

  fs.btrfs = filesystem "btrfs";
  fs.ext4 = filesystem "ext4";
  fs.vfat = filesystem "vfat";
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
      (fs.ext4 "/" "/dev/disk/by-uuid/64d05a5c-e962-4fb4-9c16-9185dcff2dad" null)
      (fs.vfat "/boot" "/dev/disk/by-uuid/FC03-65D6" null)
      (swap "/dev/disk/by-uuid/4c073557-45f2-43f3-8c77-c5254917c2de")
      {
        # Not sure where these belong, or what they do. Just put here for now. TODO: cleanup.
        boot.initrd.availableKernelModules = ["xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod"];
        boot.initrd.kernelModules = [];
        boot.kernelModules = ["kvm-intel"];
        boot.extraModulePackages = [];
      }
    ])

    (config "sodium" "x86_64-linux" [
      (cpu "amd")
      (fs.btrfs "/" "/dev/disk/by-uuid/95fa9d93-08ac-4812-b61b-2a035be81de3" ["subvol=@"])
      (fs.vfat "/boot" "/dev/disk/by-uuid/8F90-3604" null)
      (swap "/dev/disk/by-uuid/1169f8ac-71d2-4b99-a5a3-b0391f015062")
      {
        boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "ahci" "usbhid" "sd_mod"];
        boot.initrd.kernelModules = [];
        boot.kernelModules = ["kvm-amd"];
        boot.extraModulePackages = [];
      }
      nixos-hardware.nixosModules.common-gpu-amd-southern-islands
    ])
  ]
