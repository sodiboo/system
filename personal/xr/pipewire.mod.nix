{
  sodium =
    { pkgs, ... }:
    {
      services.pipewire.wireplumber.extraConfig."99-vive-pro-microphone" = {
        "monitor.alsa.rules" = [
          {
            matches = [
              { "node.name" = "alsa_input.usb-HTC_VIVE_Pro_Mutimedia_Audio-00.analog-stereo"; }
            ];

            actions = {
              update-props = {
                "node.nick" = "VIVE Pro (raw)";
                "node.description" = "VIVE Pro (raw)";

                # IMPORTANT: by default, at 48 kHz, i sound like glorp!!!
                # Instead, i set this to 44.1 kHz. PipeWire resamples it to 48kHz and it sounds fine.
                "audio.rate" = 44100;
                "audio.allowed-rates" = [ 44100 ];
              };
            };
          }
        ];
        "wireplumber.profiles" = {
          main = {
            "node.software-dsp" = "required";
          };
        };

        "node.software-dsp.rules" = [
          {
            matches = [
              { "node.name" = "alsa_input.usb-HTC_VIVE_Pro_Mutimedia_Audio-00.analog-stereo"; }
            ];
            actions = {
              create-filter = {
                filter-graph = {
                  "node.description" = "VIVE Pro (rnnoise)";
                  "media.name" = "VIVE Pro (rnnoise)";
                  "filter.graph" = {
                    nodes = [
                      {
                        type = "ladspa";
                        name = "vive_rnnoise";
                        plugin = "${pkgs.rnnoise-plugin}/lib/ladspa/librnnoise_ladspa.so";
                        label = "noise_suppressor_stereo";
                        control = {
                          "VAD Threshold (%)" = 50.0;
                          "VAD Grace Period (ms)" = 200;
                          "Retroactive VAD Grace (ms)" = 0;
                        };
                      }
                    ];
                  };

                  "capture.props" = {
                    "node.name" = "capture.vive_rnnoise_source";
                    "node.passive" = true;
                    "audio.rate" = 48000;

                    "target.object" = "alsa_input.usb-HTC_VIVE_Pro_Mutimedia_Audio-00.analog-stereo";
                  };
                  "playback.props" = {
                    "node.name" = "vive_rnnoise_source";
                    "media.class" = "Audio/Source";
                    "audio.rate" = 48000;
                  };
                };
              };
            };
          }
        ];
      };

      # sounds terrible when Monado or SteamVR are running.
      # workaround: set the GPU audio output to be the vive pro port (for some reason this makes USB audio sound fine???)
      services.pipewire.wireplumber.extraConfig."99-vive-pro-output" = {
        "monitor.alsa.rules" = [
          {
            matches = [
              { "node.name" = "alsa_output.usb-HTC_VIVE_Pro_Mutimedia_Audio-00.analog-stereo"; }
            ];

            actions = {
              update-props = {
                "node.nick" = "VIVE Pro";
                "node.description" = "VIVE Pro";
              };
            };
          }
        ];
      };
    };
}
