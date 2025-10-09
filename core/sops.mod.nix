{ sops-nix, ... }:
{
  universal =
    { pkgs, config, ... }:
    {
      imports = [ sops-nix.nixosModules.sops ];
      sops.age.sshKeyPaths =
        if config.environment.persistence."/nix/persist".enable then
          # secrets are decrypted *before* persistence kicks in
          [ "/nix/persist/etc/ssh/ssh_host_ed25519_key" ]
        else
          [ "/etc/ssh/ssh_host_ed25519_key" ];
      sops.defaultSopsFormat = "yaml";
      environment.systemPackages = [ pkgs.sops ];
    };

  carbon.sops.defaultSopsFile = ./secrets/carbon.yaml;
  iridium.sops.defaultSopsFile = ./secrets/iridium.yaml;
  oxygen.sops.defaultSopsFile = ./secrets/oxygen.yaml;
  plutonium.sops.defaultSopsFile = ./secrets/plutonium.yaml;
  sodium.sops.defaultSopsFile = ./secrets/sodium.yaml;
  nitrogen.sops.defaultSopsFile = ./secrets/nitrogen.yaml;
}
