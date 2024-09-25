{
  personal.modules = [
    ({lib, ...}: {
      nixpkgs.overlays = [
        (final: prev: {
          sodi-x-run-env = let
            wl-copy = lib.getExe' final.wl-clipboard "wl-copy";
            wl-paste = lib.getExe' final.wl-clipboard "wl-paste";
            xclip = lib.getExe final.xclip;
            clipnotify = lib.getExe final.clipnotify;
            metacity = lib.getExe final.metacity;
          in
            # Here, we use xclip over xsel because it supports binary data.
            # Additionally, we sha256sum that binary data so no shell fuckery happens to null bytes.
            # Doing so ensures we don't overwrite image/png data, among others.
            # See also: https://gaysex.cloud/notes/9v1o3sc3q66f0mrr
            final.writeShellScriptBin "x-run-env" ''

              primary-wl-to-x () {
                while read; do
                  if [[ "$(${wl-paste} --primary --no-newline | sha256sum)" != "$(${xclip} -selection primary -out | sha256sum)" ]]; then
                    echo "syncing primary wl->x"
                    ${wl-paste} --primary --no-newline | ${xclip} -selection primary -in
                  fi
                done < <(${wl-paste} --primary --watch echo)
              }

              primary-x-to-wl () {
                while ${clipnotify} -s primary; do
                  if [[ "$(${wl-paste} --primary --no-newline | sha256sum)" != "$(${xclip} -selection primary -out | sha256sum)" ]]; then
                    echo "syncing primary x->wl"
                    ${xclip} -selection primary -out | ${wl-copy} --primary
                  fi
                done
              }

              clipboard-wl-to-x () {
                while read; do
                  if [[ "$(${wl-paste} --no-newline | sha256sum)" != "$(${xclip} -selection clipboard -out | sha256sum)" ]]; then
                    echo "syncing clipboard wl->x"
                    ${wl-paste} --no-newline | ${xclip} -selection clipboard -in
                  fi
                done < <(${wl-paste} --watch echo)
              }

              clipboard-x-to-wl () {
                while ${clipnotify} -s clipboard; do
                  if [[ "$(${wl-paste} --no-newline | sha256sum)" != "$(${xclip} -selection clipboard -out | sha256sum)" ]]; then
                    echo "syncing clipboard x->wl"
                    ${xclip} -selection clipboard -out | ${wl-copy}
                  fi
                done
              }

              clipboard-wl-to-x &
              clipboard-x-to-wl &
              primary-wl-to-x &
              primary-x-to-wl &

              ${metacity} &

              "$@"
            '';
          sodi-x-run = final.writeShellScriptBin "x-run" ''
            ${lib.getExe final.xwayland-run} -- ${lib.getExe final.sodi-x-run-env} "$@"
          '';
        })
      ];
    })
  ];
  personal.home_modules = [
    ({pkgs, ...}: {
      home.packages = with pkgs; [
        xwayland
        xwayland-run
        xsel
        xclip
        metacity
        sodi-x-run
      ];
    })
  ];
}
