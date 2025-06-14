{

  universal =
    { lib, config, ... }:
    {
      options.do-auto-garbage-collection = lib.mkEnableOption "auto garbage collection";

      config = lib.mkIf config.do-auto-garbage-collection {

        programs.nh.clean = {
          enable = true;
          extraArgs = "--keep 3 --keep-since 7d";
          # this is somewhere in the middle of my commute to school.
          # and if i'm not at school, i'm likely asleep.
          dates = "Mon..Fri *-*-* 07:00:00";
        };

        nix.optimise = {
          automatic = true;
          # why is that a list?
          dates = [ "Mon..Fri *-*-* 07:30:00" ];
        };

        # I don't want these to be persistent or have any delay.
        # They don't need to run daily; if they miss a day, it's fine.
        # And i don't want them to ever delay until e.g. i'm at school
        # because that will impact my workflow if i want to remote in.
        systemd.timers =
          let
            fuck-off.timerConfig = {
              Persistent = lib.mkForce false;
              RandomizedDelaySec = lib.mkForce 0;
            };
          in
          {
            nh-clean = fuck-off;
            nix-optimise = fuck-off;
          };
      };
    };

  # This is the host that rebuilds my config and is a binary cache.
  # It is crucial to garbage collect here, or the disk will fill up automatically.
  iridium.do-auto-garbage-collection = true;

  # On my personal workstation, i frequently work on Nix code, which means lots of rebuilds.
  # I'd rather keep it snappy.
  sodium.do-auto-garbage-collection = true;

  # On my public-facing VPS, i do *not* want to auto garbage collect.
  # That's because it doesn't actually fill up automatically,
  # and i'd rather not disturb the public-facing services.
  oxygen.do-auto-garbage-collection = false;

  # On my laptop, i also do not want to auto garbage collect.
  # It's not on frequently enough for the schedule to be useful,
  # and i'd rather it not interrupt my normal use.
  nitrogen.do-auto-garbage-collection = false;
}
