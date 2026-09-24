{
  nitrogen = { lib, ... }: {
    options.internyet.inspect = lib.mkEnableOption "auxiliary configuration that allows inspecting the local services (running this config without errors) outside of the duration of the event (i.e. without `Internyet DNS` or DHCP or valid HTTPS certificates)";

    config = {
      internyet.inspect = true;
    };
  };
}
