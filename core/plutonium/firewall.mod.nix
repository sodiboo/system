# when the container is sus
{
  plutonium =
    { config, ... }:
    {
      # Don't allow anything on *both* interfaces. Explicitly choose which interface anything is allowed through on.
      assertions =
        let
          cfg = config.networking.firewall;
          check = proto: [
            {
              assertion = cfg."allowed${proto}Ports" == [ ];
              message = "The following ${proto} ports are open on all interfaces on plutonium: ${
                builtins.concatStringsSep " " (map toString cfg."allowed${proto}Ports")
              }";
            }
            {
              assertion = cfg."allowed${proto}PortRanges" == [ ];
              message = "The following ${proto} port ranges are open on all interfaces on plutonium: ${
                builtins.concatStringsSep " " (
                  map ({ from, to }: "${toString from}..${toString to}") cfg."allowed${proto}PortRanges"
                )
              }";
            }
          ];
        in
        check "TCP" ++ check "UDP";
    };
}
