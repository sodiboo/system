{
  lib,
  runCommand,
  ripgrep,
  moreutils,
  pandoc,
}:
runCommand "nginx-static"
  {
    buildInputs = [
      ripgrep
      moreutils
      pandoc
    ];
    src = ./generate;
    static = ./static;
    template = ./template.html;
  }
  ''
    exec ${./impl.sh}
  ''
