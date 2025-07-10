inputs: {
  personal.home-shortcut =
    {
      lib,
      pkgs,
      ...
    }:
    let
      package = inputs.swww.packages.${pkgs.system}.swww;
      namespaces = [
        "main"
        "overview"
      ];
    in
    {
      home.packages = [ package ];

      transient-session.services = builtins.listToAttrs (
        builtins.map (namespace: {
          name = "swww-${namespace}@";
          value = {
            Service.ExecStart = "${lib.getExe' package "swww-daemon"} -n ${namespace}";
          };
        }) namespaces
      );
    };
}
