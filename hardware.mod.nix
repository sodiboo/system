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
  fs.ntfs = filesystem "ntfs-3g";
  fs.ext4 = filesystem "ext4";
  fs.vfat = filesystem "vfat";
  swap = device: {swapDevices = [{inherit device;}];};

  cpu = brand: {hardware.cpu.${brand}.updateMicrocode = true;};

  qemu = {modulesPath, ...}: {
    imports = ["${modulesPath}/profiles/qemu-guest.nix"];
  };
in
  {
    universal.modules = [
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
      (fs.ntfs "/mnt/win" "/dev/disk/by-uuid/764227D842279C3D" ["rw" "uid=1000"])
      (fs.ntfs "/mnt/games" "/dev/disk/by-uuid/5480A73980A7208A" ["rw" "uid=1000"])
      (fs.vfat "/boot" "/dev/disk/by-uuid/8F90-3604" null)
      (swap "/dev/disk/by-uuid/6341aab8-dcda-444e-9e21-40236ae1ccd8")
      {
        boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "ahci" "usbhid" "sd_mod"];
        boot.initrd.kernelModules = [];
        boot.kernelModules = ["kvm-amd"];
        boot.extraModulePackages = [];
        boot.supportedFilesystems = ["ntfs"];
      }
      nixos-hardware.nixosModules.common-gpu-amd-southern-islands
    ])

    # Contabo VPS
    (config "oxygen" "x86_64-linux" [
      qemu
      (fs.ext4 "/" "/dev/sda3" null)
      {
        boot.tmp.cleanOnBoot = true;
        zramSwap.enable = true;
        boot.loader.grub.device = "/dev/sda";
        boot.initrd.availableKernelModules = ["ata_piix" "uhci_hcd" "xen_blkfront" "vmw_pvscsi"];
        boot.initrd.kernelModules = ["nvme"];
      }
    ])
  ]
