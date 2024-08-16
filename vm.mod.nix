{
  # Intentionally not in `universal` because you should not be running my servers as a VM. They rely on physical properties.
  personal.modules = [
    ({lib, ...}: {
      virtualisation.vmVariant = {
        users.users.sodiboo.hashedPassword = "";
        services.getty.autologinUser = "sodiboo";
        security.sudo.wheelNeedsPassword = false;

        services.qemuGuest.enable = true;

        services.spice-vdagentd.enable = true;
        virtualisation.qemu.options = [
          "-vga std -device virtio-serial-pci -spice port=5930,disable-ticketing=on -device virtserialport,chardev=spicechannel0,name=com.redhat.spice.0 -chardev spicevmc,id=spicechannel0,name=vdagent"
        ];

        services.openssh.enable = true;
        services.openssh.settings = {
          PermitEmptyPasswords = true;
          UsePAM = false;
        };
        networking.firewall.enable = false;
        virtualisation.forwardPorts = [
          {
            from = "host";
            host.port = 2222;
            guest.port = 22;
          }
        ];

        services.greetd.enable = lib.mkForce false;

        virtualisation.memorySize = 4096;
        virtualisation.cores = 4;
      };
    })
  ];

  sodium.modules = [
    {
      virtualisation.vmVariant.services.openvpn.servers.sodium.autoStart = false;
    }
  ];
}
