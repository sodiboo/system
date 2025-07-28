{ disko, ... }:
{
  iridium = {
    imports = [ disko.nixosModules.disko ];

    disko.devices = {
      disk =
        let
          devices = {
            disk-1 = "/dev/disk/by-id/ata-WDC_WD30EFRX-68EUZN0_WD-WCC4N2JHUTEL";
            disk-2 = "/dev/disk/by-id/ata-WDC_WD30EFRX-68EUZN0_WD-WCC4N5JV5Y5T";
            disk-3 = "/dev/disk/by-id/ata-WDC_WD30EZRX-00MMMB0_WD-WCAWZ2074186";
            disk-4 = "/dev/disk/by-id/ata-WDC_WD30EZRX-00MMMB0_WD-WCAWZ2114096";
          };
        in
        builtins.mapAttrs (_: device: {
          type = "disk";
          inherit device;

          content = {
            type = "lvm_pv";
            vg = "storage-pool";
          };
        }) devices;

      lvm_vg.storage-pool = {
        type = "lvm_vg";
        lvs.storage = {
          size = "100%";
          extraArgs = [
            # by default, a RAID5 VG only stripes like two of my PVs???
            # and this is just like, an option to make it stripe them all???
            # why is this not inferred from "100%". who hurt you, LVM?
            "--config allocation/raid_stripe_all_devices=1"
          ];
          lvm_type = "raid5";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/storage";
          };
        };
      };
    };
  };
}
