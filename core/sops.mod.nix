{ sops-nix, ... }:
{
  universal =
    { pkgs, ... }:
    {
      imports = [ sops-nix.nixosModules.sops ];
      sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      sops.defaultSopsFormat = "yaml";
      environment.systemPackages = [ pkgs.sops ];
    };

  iridium.sops.defaultSopsFile = ./secrets/iridium.yaml;
  oxygen.sops.defaultSopsFile = ./secrets/oxygen.yaml;
  sodium.sops.defaultSopsFile = ./secrets/sodium.yaml;
  nitrogen.sops.defaultSopsFile = ./secrets/nitrogen.yaml;
}
