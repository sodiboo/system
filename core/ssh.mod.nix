{
  universal = {
    services.openssh.enable = true;
    services.openssh.settings.PasswordAuthentication = false;

    services.openssh.hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];

    environment.persistence."/nix/persist".files = [ "/etc/ssh/ssh_host_ed25519_key" ];
  };
}
