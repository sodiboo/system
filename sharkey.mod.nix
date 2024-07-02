{
  oxygen.modules = [
    ({
      pkgs,
      config,
      ...
    }: {
      services.sharkey.enable = true;
      services.sharkey.database.passwordFile = config.sops.secrets.sharkey-db-password.path;
      services.sharkey.redis.passwordFile = config.sops.secrets.sharkey-redis-password.path;
      services.sharkey.settings = {
        url = "https://gaysex.cloud/";
        id = "aidx";

        port = 3001;

        maxNoteLength = 8192;
        proxyRemoteFiles = true;

        signToActivityPubGet = true;
        CheckActivityPubGetSigned = false;
      };

      services.meilisearch.masterKeyEnvironmentFile = config.sops.secrets.meili-master-key-env.path;
    })
  ];
}
