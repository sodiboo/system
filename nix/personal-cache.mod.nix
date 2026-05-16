{
  sodium =
    { config, ... }:
    {
      # read-only permissions to my personal cache.
      sops.secrets."attic/access-token" = { };

      sops.secrets."attic/private-cache-1" = { };
      sops.secrets."attic/private-key-1" = { };

      sops.templates."attic/netrc" = {
        content = ''
          machine loft.computers.gay
          password ${config.sops.placeholder."attic/access-token"}
        '';
      };

      sops.templates."attic/nix-prelude" = {
        content = ''
          extra-substituters = ${config.sops.placeholder."attic/private-cache-1"}
          extra-trusted-public-keys = ${config.sops.placeholder."attic/private-key-1"}
          netrc-file = ${config.sops.templates."attic/netrc".path}
        '';

        mode = "0444"; # <-- file must be accessible (r) to all users, because only the build daemon runs as root and not nix evaluator itself.
      };

      nix.extraOptions = ''
        !include ${config.sops.templates."attic/nix-prelude".path}
      '';

      nix.settings = {
        substituters = [ "https://loft.computers.gay/public" ];
        trusted-public-keys = [ "public:3rYwPMY0tcHRZewRO60nORNaF+n5aupI+PPQF4J/Tn8=" ];
      };
    };
}
