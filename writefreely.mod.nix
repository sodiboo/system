{
  oxygen.modules = [
    ({config, ...}: {
      services.writefreely = {
        enable = false;
        host = "infodumping.place";
        settings = {
          app.host = "https://infodumping.place";
          app.site_name = "sodiboo's infodumping garden";
          app.site_description = "personal blog of sodiboo";
          server.port = 3003;
        };
        database.type = "mysql";
        database.passwordFile = config.sops.secrets.writefreely-db-password.path;
        database.createLocally = true;
      };
    })
  ];
}
