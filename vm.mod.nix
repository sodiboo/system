{
  # Intentionally not in `universal` because you should not be running my servers as a VM. They rely on physical properties.
  personal.modules = [
    ({lib, ...}: {
      options = {
        is-virtual-machine = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether the system is a virtual machine. Used to decide certain network and peripheral settings.";
        };
      };
      config.virtualisation.vmVariant = {
        is-virtual-machine = true;

        services.openssh.enable = true;
        services.openssh.settings.PermitEmptyPasswords = true;
        users.users.sodiboo.hashedPassword = "";
        security.sudo.wheelNeedsPassword = false;

        services.qemuGuest.enable = true;

        virtualisation.qemu.options = [
          "-display sdl,gl=on"
          "-device virtio-vga-gl"
        ];

        virtualisation.memorySize = 4096;
        virtualisation.cores = 4;

        networking.wireguard.enable = lib.mkForce false;
        services.tailscale.enable = lib.mkForce false;
      };
    })
  ];

  sodium.modules = [
    {
      # virtualisation.vmVariant.services.openvpn.servers.sodium.autoStart = false;
    }
  ];
}
