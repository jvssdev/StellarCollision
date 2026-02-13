{
  config,
  lib,
  pkgs,
  inputs,
  inputs',
  ...
}:
let
  inherit (lib)
    mkIf
    getExe
    getExe'
    mkOption
    types
    ;
  cfg = config.cfg.niri;
  c = config.cfg.theme.colors;

  clipboard = pkgs.callPackage ./_fuzzel-clipboard.nix { };

  quickshell = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{

  options.cfg.niri = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Niri configuration.";
    };

    package = mkOption {
      type = lib.types.package;
      default = inputs'.niri.packages.niri-unstable;
      description = "The Niri package to install.";
    };
  };

  config = mkIf cfg.enable {
    programs.niri = {
      enable = true;
      inherit (cfg) package;
    };

    hj.packages = [
      clipboard.fuzzel-clipboard
      clipboard.fuzzel-clipboard-clear
    ];

    hj.xdg.config.files."niri/config.kdl".text = ''

      spawn-at-startup "${getExe' pkgs.dbus "dbus-update-activation-environment"}" "--systemd" "WAYLAND_DISPLAY" "XDG_CURRENT_DESKTOP"

      spawn-sh-at-startup "${getExe pkgs.fcitx5} -d --replace"
      spawn-sh-at-startup "${getExe' pkgs.networkmanagerapplet "nm-applet"} --indicator"
      spawn-sh-at-startup "${getExe' pkgs.blueman "blueman-applet"}"
      spawn-at-startup "${getExe quickshell}"
      spawn-at-startup "${getExe pkgs.gammastep} ${
        if config.cfg.gammastep.tray then "-indicator" else ""
      }"
      spawn-sh-at-startup "${getExe pkgs.wpaperd}"
      spawn-sh-at-startup "${getExe' pkgs.wl-clipboard "wl-paste"} --type text --watch ${getExe pkgs.cliphist} store"
      spawn-sh-at-startup "${getExe' pkgs.wl-clipboard "wl-paste"} --type image --watch ${getExe pkgs.cliphist} store"
      spawn-sh-at-startup "${getExe pkgs.wl-clip-persist} --clipboard regular --reconnect-tries 0"

      screenshot-path "~/Pictures/Screenshots from %Y-%m-%d %H-%M-%S.png"

      prefer-no-csd

      input {
          keyboard {
              repeat-delay 220
              repeat-rate 35
              xkb {
                  layout "br"
                  variant "abnt2"
              }
              numlock
          }

          touchpad {
              tap
              accel-speed 0.7
          }
          focus-follows-mouse
      }

      output "eDP-1" {
          mode "1920x1080@59.934"
      }

      layout {
          gaps 0
          center-focused-column "never"
          always-center-single-column

          default-column-width { proportion 0.5; }

          preset-column-widths {
              proportion 0.33333
              proportion 0.5
              proportion 0.66667
          }

          focus-ring {
              width 2
              active-color "${c.base0D}"
              inactive-color "${c.base02}"
          }

          border {
              width 2
              active-color "${c.base0D}"
              inactive-color "${c.base02}"
          }

          shadow {
              off
          }
      }

      recent-windows {
          binds {
              Mod+Tab { next-window; }
              Mod+Shift+Tab { previous-window; }
          }
      }


      environment {
          QT_QPA_PLATFORM "wayland;xcb"
          GDK_BACKEND "wayland,x11,*"
      }

      cursor {
        hide-when-typing
        hide-after-inactive-ms 1000
      }

      overview {
          workspace-shadow {
              off
              softness 40
              spread 10
              offset x=0 y=10
              color "#00000050"
          }
      }

      xwayland-satellite {
        path "${getExe pkgs.xwayland-satellite}"
      }

      window-rule {
          match is-floating=false
      }

      window-rule {
          match app-id=r#"(?i)(firefox|zen|zen-browser|zen-beta|chromium)"#
          default-column-width { proportion 1.0; }
      }

      window-rule {
          match title="Picture-in-Picture"
          open-floating true
      }

      window-rule {
          match app-id="xdg-desktop-portal-gtk"
          open-floating true
      }

      window-rule {
          match app-id="org.keepassxc.KeePassXC"
          open-floating true
      }

      window-rule {
          match app-id=r#"^org\.wezfurlong\.wezterm$"#
          default-column-width {}
      }

      binds {
          Mod+Shift+Slash { show-hotkey-overlay; }

          Mod+T { spawn "${getExe pkgs.${config.cfg.vars.terminal}}"; }
          Mod+B { spawn "${config.cfg.vars.browser}"; }
          Mod+A repeat=false { spawn "${getExe pkgs.fuzzel}"; }
          Mod+v repeat=false { spawn-sh "${getExe clipboard.fuzzel-clipboard}"; }
          Mod+Shift+v repeat=false { spawn-sh "${getExe clipboard.fuzzel-clipboard-clear}"; }

          Print { screenshot-screen; }
          Ctrl+Print { screenshot; }
          Alt+Print { screenshot-window; }

          Mod+X { spawn "${getExe quickshell} ipc call powerMenu toggle"; }
          Mod+N { spawn "${getExe quickshell} ipc call notificationCenter toggle"; }
          Mod+Q { close-window; }
          Mod+W { toggle-column-tabbed-display ; }
          Mod+Shift+C { quit; }
          Mod+Space { toggle-window-floating; }
          Mod+F { maximize-column; }
          Mod+Shift+F { fullscreen-window; }
          Mod+R { toggle-column-tabbed-display; }

            // === Window Movement ===
            Mod+Shift+Left  { move-column-left; }
            Mod+Shift+Down  { move-window-down; }
            Mod+Shift+Up    { move-window-up; }
            Mod+Shift+Right { move-column-right; }
            Mod+Shift+H     { move-column-left; }
            Mod+Shift+J     { move-window-down; }
            Mod+Shift+K     { move-window-up; }
            Mod+Shift+L     { move-column-right; }

            // === Column Navigation ===
            Mod+Home { focus-column-first; }
            Mod+End  { focus-column-last; }
            Mod+Ctrl+Home { move-column-to-first; }
            Mod+Ctrl+End  { move-column-to-last; }

            // === Tab Navigation ===
            Mod+Left { focus-window-down; }
            Mod+Right { focus-window-up; }

            // === Mouse Wheel Navigation ===
            Mod+WheelScrollDown      cooldown-ms=150 { focus-workspace-down; }
            Mod+WheelScrollUp        cooldown-ms=150 { focus-workspace-up; }
            Mod+Ctrl+WheelScrollDown cooldown-ms=150 { move-column-to-workspace-down; }
            Mod+Ctrl+WheelScrollUp   cooldown-ms=150 { move-column-to-workspace-up; }

            Mod+WheelScrollRight      { focus-column-right; }
            Mod+WheelScrollLeft       { focus-column-left; }
            Mod+Ctrl+WheelScrollRight { move-column-right; }
            Mod+Ctrl+WheelScrollLeft  { move-column-left; }

            Mod+Shift+WheelScrollDown      { focus-column-right; }
            Mod+Shift+WheelScrollUp        { focus-column-left; }
            Mod+Ctrl+Shift+WheelScrollDown { move-column-right; }
            Mod+Ctrl+Shift+WheelScrollUp   { move-column-left; }

            // === Numbered Workspaces ===
            Mod+1 { focus-workspace 1; }
            Mod+2 { focus-workspace 2; }
            Mod+3 { focus-workspace 3; }
            Mod+4 { focus-workspace 4; }
            Mod+5 { focus-workspace 5; }
            Mod+6 { focus-workspace 6; }
            Mod+7 { focus-workspace 7; }
            Mod+8 { focus-workspace 8; }
            Mod+9 { focus-workspace 9; }

            // === Move to Numbered Workspaces ===
            Mod+Shift+1 { move-column-to-workspace 1; }
            Mod+Shift+2 { move-column-to-workspace 2; }
            Mod+Shift+3 { move-column-to-workspace 3; }
            Mod+Shift+4 { move-column-to-workspace 4; }
            Mod+Shift+5 { move-column-to-workspace 5; }
            Mod+Shift+6 { move-column-to-workspace 6; }
            Mod+Shift+7 { move-column-to-workspace 7; }
            Mod+Shift+8 { move-column-to-workspace 8; }
            Mod+Shift+9 { move-column-to-workspace 9; }

            // === Column Management ===
            Mod+BracketLeft  { consume-or-expel-window-left; }
            Mod+BracketRight { consume-or-expel-window-right; }
            Mod+Period { expel-window-from-column; }

            // === Sizing & Layout ===
            Mod+Shift+R { switch-preset-column-width; }
            Mod+Ctrl+R { reset-window-height; }
            Mod+Ctrl+F { expand-column-to-available-width; }
            Mod+C { center-column; }
            Mod+Ctrl+C { center-visible-columns; }

            // === Manual Sizing ===
            Mod+Minus { set-column-width "-10%"; }
            Mod+Equal { set-column-width "+10%"; }
            Mod+Shift+Minus { set-window-height "-10%"; }
            Mod+Shift+Equal { set-window-height "+10%"; }

            XF86AudioRaiseVolume allow-when-locked=true { spawn "${getExe' pkgs.wireplumber "wpctl"}" "set-volume" "-l" "1.5" "@DEFAULT_AUDIO_SINK@" "5+%"; }
            XF86AudioLowerVolume allow-when-locked=true { spawn "${getExe' pkgs.wireplumber "wpctl"}" "set-volume" "-l" "1.5" "@DEFAULT_AUDIO_SINK@" "5-%"; }
            XF86AudioMute        allow-when-locked=true { spawn "${getExe' pkgs.wireplumber "wpctl"}" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
            XF86AudioMicMute     allow-when-locked=true { spawn "${getExe' pkgs.wireplumber "wpctl"}" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"; }

            XF86MonBrightnessUp   allow-when-locked=true { spawn "${getExe pkgs.brightnessctl}" "-e4" "-n2" "set" "5+%"; }
            XF86MonBrightnessDown allow-when-locked=true { spawn "${getExe pkgs.brightnessctl}" "-e4" "-n2" "set" "5-%"; }

            XF86AudioPlay allow-when-locked=true { spawn "${getExe pkgs.playerctl}" "play-pause"; }
            XF86AudioPause allow-when-locked=true { spawn "${getExe pkgs.playerctl}" "play-pause"; }
            XF86AudioNext allow-when-locked=true { spawn "${getExe pkgs.playerctl}" "next"; }
            XF86AudioPrev allow-when-locked=true { spawn "${getExe pkgs.playerctl}" "previous"; }
        }
    '';
  };
}
