inputs: {
  personal.home-shortcut =
    {
      lib,
      pkgs,
      ...
    }:
    let
      package = inputs.nixpkgs-wayland.packages.${pkgs.stdenv.hostPlatform.system}.swww;
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
