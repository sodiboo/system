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

    personal.modules = [
      {
        services.fwupd.enable = true;
      }
    ];
  }
  // builtins.listToAttrs [
    (config "sodium" "x86_64-linux" [
      (cpu "amd")
      (fs.btrfs "/" "/dev/disk/by-uuid/95fa9d93-08ac-4812-b61b-2a035be81de3" ["subvol=@"])
      (fs.ntfs "/mnt/win" "/dev/disk/by-uuid/764227D842279C3D" ["rw" "uid=1000"])
      (fs.ntfs "/mnt/games" "/dev/disk/by-uuid/5480A73980A7208A" ["rw" "uid=1000"])
      (fs.vfat "/boot" "/dev/disk/by-uuid/8F90-3604" null)
      (fs.ext4 "/mnt/lithium-graveyard" "/dev/disk/by-uuid/64d05a5c-e962-4fb4-9c16-9185dcff2dad" null)
      (fs.vfat "/mnt/lithium-graveyard/boot" "/dev/disk/by-uuid/FC03-65D6" null)
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

    (config "nitrogen" "x86_64-linux" [
      (cpu "intel")
      (fs.ext4 "/" "/dev/disk/by-uuid/5cca29ad-a848-417e-9bd8-31b0f3be0543" null)
      (fs.vfat "/boot" "/dev/disk/by-uuid/1202-D996" null)
      (swap "/dev/disk/by-uuid/310e4198-ae8a-44f2-ac58-9da6ea3dbcd7")
      {
        boot.initrd.availableKernelModules = ["xhci_pci" "nvme" "usbhid" "usb_storage" "sd_mod" "rtsx_usb_sdmmc"];
        boot.initrd.kernelModules = [];
        boot.kernelModules = ["kvm-intel"];
        boot.kernelParams = ["iomem=relaxed"];
        boot.extraModulePackages = [];
      }
    ])

    (config "iridium" "x86_64-linux" [
      (cpu "intel")
      (fs.ext4 "/" "/dev/disk/by-uuid/8fa79a3b-aebf-4be7-8698-f59f3db0752f" null)
      {
        boot.loader.grub.enable = true;
        boot.loader.grub.device = "/dev/disk/by-id/wwn-0x5000c5004f368909";

        boot.initrd.availableKernelModules = ["ahci" "ohci_pci" "ehci_pci" "usb_storage" "usbhid" "sd_mod"];
        boot.initrd.kernelModules = [];
        boot.kernelModules = ["kvm-amd"];
        boot.extraModulePackages = [];
        boot.supportedFilesystems = ["ntfs"];
      }
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
