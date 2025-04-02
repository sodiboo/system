{firefox-addons, ...}: {
  personal.home_modules = [
    {
      programs.floorp = {
        enable = true;

        profiles.sodiboo = {
          extensions = {
            force = true;
            packages = with firefox-addons.packages.x86_64-linux; [
              consent-o-matic
              ublock-origin
              darkreader
              bitwarden
              libredirect
              dearrow
              shinigami-eyes
              web-archives
              user-agent-string-switcher
              indie-wiki-buddy
            ];
          };

          containersForce = true;
          containers = {
            school = {
              id = 1; # <-- by default, `id=0` which conflicts with the ephemeral "Private" container.
              name = "School";
              icon = "fruit";
              color = "green";
            };
          };
        };
        policies = {
          FirefoxHome = {
            SponsoredTopSites = false;
            SponsoredPocket = false;
          };
        };
      };

      stylix.targets.floorp.profileNames = ["sodiboo"];
    }
  ];
}
