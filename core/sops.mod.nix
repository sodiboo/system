{ sops-nix, ... }:
{
  universal =
    { pkgs, ... }:
    {
      imports = [ sops-nix.nixosModules.sops ];
      sops.defaultSopsFormat = "yaml";
      environment.systemPackages = [ pkgs.sops ];
    };

  iridium = {
    sops.defaultSopsFile = ./secrets/iridium.yaml;
    sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  };

  oxygen = {
    sops.defaultSopsFile = ./secrets/oxygen.yaml;
    sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  };

  sodium = {
    sops.defaultSopsFile = ./secrets/sodium.yaml;
    sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  };

  nitrogen = {
    sops.defaultSopsFile = ./secrets/nitrogen.yaml;
    sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  };
}
