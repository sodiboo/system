{
  personal.imports = [
    {
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
        #media-session.enable = true;
      };
      # this is the loopback device created in ALSA.
      # it's just annoying, and i can create loopbacks on demand with `pw-loopback`.
      boot.blacklistedKernelModules = [ "snd_aloop" ];
    }
    {
      # Bluetooth audio devices come with multiple profiles:
      # One important profile is the "headset" profile, which has a microphone (as opposed to headphones with no mic)
      # and the other is the Advanced Audio Distribution Profile (A2DP), which is used for high quality audio.
      # The headset profile has absolutely terrible audio quality, and i never want to use it.
      # And, my computer has a separate microphone anyway, so i don't need the headset profile's microphone.
      # Let's just never switch to the headset profile.
      services.pipewire.wireplumber.extraConfig."51-mitigate-annoying-profile-switch" = {
        "wireplumber.settings" = {
          "bluetooth.autoswitch-to-headset-profile" = false;
        };
      };

      # Some apps fuck with settings that i don't want to persist.
      # My whole audio setup should be configured statically.
      # TODO: actually configure volumes (raw mic 60%, rnnoise 130%)
      services.pipewire.wireplumber.extraConfig."51-stop-restoring-shit-you-cunt" = {
        "wireplumber.settings" = {
          "device.restore-profile" = false;
          "device.restore-routes" = false;
          "node.stream.restore-props" = false;
          "node.stream.restore-target" = false;
          "node.restore-default-targets" = false;
        };
      };
    }
  ];

  personal.home-shortcut =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        qpwgraph
        helvum
      ];
    };

  sodium =
    { pkgs, ... }:
    {
      services.pipewire.extraConfig.pipewire."99-filter" = {
        "context.modules" = [
          {
            name = "libpipewire-module-filter-chain";
            args = {
              "node.description" = "RØDE XCM-50 (rnnoise)";
              "media.name" = "RØDE XCM-50 (rnnoise)";
              "filter.graph" = {
                nodes = [
                  {
                    type = "ladspa";
                    name = "rnnoise";
                    plugin = "${pkgs.rnnoise-plugin}/lib/ladspa/librnnoise_ladspa.so";
                    label = "noise_suppressor_mono";
                    control = {
                      "VAD Threshold (%)" = 50.0;
                      "VAD Grace Period (ms)" = 200;
                      "Retroactive VAD Grace (ms)" = 0;
                    };
                  }
                ];
              };

              "capture.props" = {
                "node.name" = "capture.rnnoise_source";
                "node.passive" = true;
                "audio.rate" = 48000;

                "target.node" = "alsa_input.usb-R__DE_R__DE_XCM-50_F5CD4617-00.mono-fallback";
                #                                ^^    ^^
                # hahaha what the hell are these underscores
              };
              "playback.props" = {
                "node.name" = "rnnoise_source";
                "media.class" = "Audio/Source";
                "audio.rate" = 48000;
              };
            };
          }
        ];
      };

      services.pipewire.wireplumber.extraConfig."99-rename" = {
        "monitor.alsa.rules" = [
          {
            matches = [
              # Matching the model number of the monitor instead of the node name.
              # This is done to ensure that it is based on the monitor and not the port.
              { "node.nick" = "LC49G95T"; }
            ];

            actions = {
              update-props = {
                # Again, i want to show the name in waybar rather than the model number.
                "node.nick" = "Samsung Odyssey G9";
                # Without an override, the description will be "Navi 31 HDMI/DP Audio Digital Stereo (HDMI)"
                # Which is unhelpful, and also wrong. This monitor is plugged in via DP.
                "node.description" = "Samsung Odyssey G9";
              };
            };
          }
          {
            matches = [
              # not sure what this is.
              { "node.name" = "alsa_output.pci-0000_6b_00.6.iec958-stereo"; }
              { "node.name" = "alsa_input.pci-0000_6b_00.6.analog-stereo"; }
              { "device.name" = "alsa_card.pci-0000_6b_00.6"; }
            ];

            actions = {
              update-props = {
                "node.disabled" = true;
              };
            };
          }
          {
            matches = [
              # My RØDE microphone has an analog output.
              # When headphones are plugged in, it will composite mic feedback into the output.
              # That's actually pretty cool, but i don't use it, and *this output appears when nothing is plugged in*.
              # So, remove it. It's annoying when it accidentally gets selected.
              { "node.description" = "RØDE XCM-50 Analog Stereo"; }
            ];

            actions = {
              update-props = {
                "node.disabled" = true;
              };
            };
          }
          {
            matches = [
              { "node.name" = "alsa_input.usb-R__DE_R__DE_XCM-50_F5CD4617-00.mono-fallback"; }
            ];

            actions = {
              update-props = {
                "node.nick" = "RØDE XCM-50 (raw)";
                "node.description" = "RØDE XCM-50 (raw)";
              };
            };
          }
        ];
      };
    };

  nitrogen = {
    services.pipewire.wireplumber.extraConfig."99-rename" = {
      "monitor.alsa.rules" = [
        {
          matches = [
            { "node.name" = "alsa_output.pci-0000_00_1f.3.analog-stereo"; }
            { "node.name" = "alsa_input.pci-0000_00_1f.3.analog-stereo"; }
          ];

          actions = {
            update-props = {
              "node.nick" = "Built-in Audio";
              "node.description" = "Built-in Audio";
            };
          };
        }
      ];
    };
  };
}
