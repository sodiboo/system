{ disko, ... }:
{
  carbon =
    { modulesPath, ... }:
    {
      imports = [
        "${modulesPath}/profiles/qemu-guest.nix"
        disko.nixosModules.disko
      ];

      networking.hostName = "carbon";
      nixpkgs.hostPlatform = "x86_64-linux";

      boot.initrd.availableKernelModules = [
        "ata_piix"
        "uhci_hcd"
        "virtio_pci"
        "sr_mod"
        "virtio_blk"
      ];

      disko.devices = {
        disk.main = {
          type = "disk";
          device = "/dev/disk/by-id/virtio-019197675b984e1ba42c";
          content = {
            type = "gpt";
            partitions = {
              boot = {
                size = "1M";
                type = "EF02";
              };
              main = {
                size = "100%";
                content = {
                  type = "btrfs";
                  subvolumes = {
                    "@boot" = {
                      mountpoint = "/boot";
                    };
                    "@nix" = {
                      mountpoint = "/nix";
                      mountOptions = [
                        "noatime"
                        "compress=zstd"
                      ];
                    };
                    "@persist" = {
                      mountpoint = "/nix/persist";
                      mountOptions = [
                        "noatime"
                        "compress=zstd"
                      ];
                    };
                  };
                };
              };
            };
          };
        };

        nodev."/" = {
          fsType = "tmpfs";
          mountOptions = [
            "defaults"
            "size=128M"
            "mode=0755"
          ];
        };
      };

      fileSystems."/nix/persist".neededForBoot = true;
      environment.persistence."/nix/persist".enable = true;
    };
}
