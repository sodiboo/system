{
  iridium =
    { pkgs, ... }:
    {
      users.users.remote-builder = {
        isSystemUser = true;
        group = "remote-builder";
        description = "trusted remote builder user";
        shell = pkgs.runtimeShell;
      };

      users.groups.remote-builder = { };

      users.users.remote-builder.openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBIwHeeSm7ten3Rxqj90xaBWgyRw1xYqBjKBj8nevFOD remote-builder"
      ];

      nix.settings.trusted-users = [ "remote-builder" ];
    };

  nitrogen =
    { config, ... }:
    {
      sops.secrets.remote-build-ssh-id = { };
      programs.ssh.extraConfig = ''
        Host iridium
          HostName iridium.wg
          User remote-builder
          IdentityFile ${config.sops.secrets.remote-build-ssh-id.path}
      '';

      nix.distributedBuilds = true;
      nix.buildMachines = [
        {
          hostName = "iridium";
          system = "x86_64-linux";

          maxJobs = 4;
        }
      ];
    };
}
