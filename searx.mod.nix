{
  oxygen.modules = [
    {
      services.searx.enable = true;
      services.searx.settings = {
        server = {
          port = 3002;
          bind_address = "127.0.0.1";
          secret_key = "spotting-gumminess-chamomile-unsuited-purple";
          image_proxy = true;
        };
      };
    }
  ];
}
