# rebuild based on the justfile in this repo.
{
  universal =
    {
      pkgs,
      lib,
      ...
    }:
    let
      rebuild-shorthand = pkgs.writeShellScriptBin "nixos" ''
        exec ${lib.getExe pkgs.just} -f /etc/nixos/justfile sys "$@"
      '';
    in
    {
      programs.nh.enable = true;
      environment.systemPackages = [ rebuild-shorthand ];
    };
}
