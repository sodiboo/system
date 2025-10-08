# Nix ecosystem is centered around GitHub, but their unauthenticated rate limits are too low.
# So, it is practically necessary to have a personal access token to comfortably use Nix.
{
  physical =
    { config, ... }:
    {
      # This token has no permissions, so it cannot do anything other than read public repositories.
      sops.secrets.github-access-token = { };

      sops.templates.access-token-prelude = {
        content = ''
          access-tokens = github.com=${config.sops.placeholder.github-access-token}
        '';

        mode = "0444"; # <-- file must be accessible (r) to all users, because only the build daemon runs as root and not nix evaluator itself.
      };

      nix.extraOptions = ''
        !include ${config.sops.templates.access-token-prelude.path}
      '';
    };
}
