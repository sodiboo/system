{
  universal = {
    services.openssh = {
      enable = true;
      settings = {
        AuthenticationMethods = "publickey";
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };

      authorizedKeysInHomedir = false;

      hostKeys = [
        {
          path = "/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
      ];
    };

    environment.persistence."/nix/persist".files = [ "/etc/ssh/ssh_host_ed25519_key" ];
  };
}
