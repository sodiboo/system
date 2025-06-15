# rebuild based on the justfile in this repo.
{
  universal =
    {
      pkgs,
      lib,
      ...
    }:
    let
      rebuild-shorthand-exe = "nixos";

      rebuild-shorthand =
        pkgs.runCommand "system-rebuild-shorthand"
          {
            nativeBuildInputs = [
              pkgs.makeWrapper
            ];
          }
          ''
            makeWrapper ${lib.getExe pkgs.just} $out/bin/${rebuild-shorthand-exe} \
              --add-flags "-f /etc/nixos/justfile sys" \
              --prefix PATH : ${lib.makeBinPath [ pkgs.nixfmt-rfc-style ]}
          '';
    in
    {
      programs.nh.enable = true;
      environment.systemPackages = [ rebuild-shorthand ];
    };
}
