{
  # Intentionally not in `universal` because you should not be running my servers as a VM. They rely on physical properties.
  personal =
    {
      lib,
      config,
      ...
    }:
    {
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

        home-shortcut.programs.niri.settings.input = {
          mod-key = "Alt";
          mod-key-nested = "Mod5"; # AltGr
        };

        environment.etc.issue.text = ''
          Welcome to ${config.networking.hostName}! You're in a virtual machine.

          ---

          Compositor binds are based on Alt, because
          i expect your host OS to be using Super.

          Also, surprise! You're using a Nordic layout.
          I don't know a good way to change that for you.

          ---

          The compositor may also fail to launch;
          this is somewhat inconsistent.

          Try `ssh`ing in and checking
          `systemctl --user status niri`
          if that happens.

          The most common fix is to just reboot the VM.
          Press F12 to do that.

          ---

          Press Ctrl+Alt+G to release the keyboard from the VM.

          ---

          The user is `sodiboo` and there is no password.

          ---
        '';

        virtualisation.memorySize = 4096;
        virtualisation.cores = 4;

        vpn.enable = lib.mkForce false;
        services.tailscale.enable = lib.mkForce false;
      };
    };
}
