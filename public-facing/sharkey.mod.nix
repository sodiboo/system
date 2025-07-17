{
  oxygen =
    {
      pkgs,
      config,
      ...
    }:
    {
      reverse-proxy."gaysex.cloud".locations."/".localhost.port = config.services.sharkey.settings.port;

      sops.secrets.meili-master-key = { };

      services.sharkey = {
        enable = true;
        database.createLocally = true;
        redis.createLocally = true;
        meilisearch.createLocally = true;
        settings = {
          id = "aidx";
          url = "https://gaysex.cloud/";

          fulltextSearch.provider = "sqlLike";

          meilisearch.scope = "global";

          port = 3001;

          maxNoteLength = 8192;
          maxFileSize = 1024 * 1024 * 1024;
          proxyRemoteFiles = true;

          # at the suggestion of Sharkey maintainers,
          # this allows the server to run multiple workers
          # and without this (and postgres tuning), the instance runs slowly
          clusterLimit = 3;

          signToActivityPubGet = true;
          CheckActivityPubGetSigned = false;
        };
      };

      # at the suggestion of Sharkey maintainers,
      # this is postgres tuned according to https://pgtune.leopard.in.ua
      # (probably don't just copy this, but use the tool yourself)
      services.postgresql.settings = {
        max_connections = "100";
        shared_buffers = "6GB";
        effective_cache_size = "18GB";
        maintenance_work_mem = "1536MB";
        checkpoint_completion_target = "0.9";
        wal_buffers = "16MB";
        default_statistics_target = "100";
        random_page_cost = "1.1";
        effective_io_concurrency = "200";
        work_mem = "15728kB";
        huge_pages = "off";
        min_wal_size = "1GB";
        max_wal_size = "4GB";
        max_worker_processes = "8";
        max_parallel_workers_per_gather = "4";
        max_parallel_workers = "8";
        max_parallel_maintenance_workers = "4";
      };

      services.meilisearch.masterKeyFile = config.sops.secrets.meili-master-key.path;
    };
}
