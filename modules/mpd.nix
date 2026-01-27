{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkOption
    types
    mkIf
    getExe
    mkForce
    ;

  cfg = config.cfg.mpd;
  homeDir = config.cfg.vars.homeDirectory;
  xdgConfig = config.hj.xdg.config.directory;
  xdgState = config.hj.xdg.state.directory;
in
{
  options.cfg.mpd = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable MPD backend.";
    };
  };

  config = mkIf cfg.enable {

    services = {
      playerctld.enable = true;
      mpd.enable = mkForce false;
    };

    hj.xdg.config.files = {
      "mpd/mpd.conf".text = ''
        music_directory      "${homeDir}/Media/Music"
        playlist_directory   "${xdgConfig}/mpd/playlists"
        state_file           "${xdgState}/mpd/state"
        sticker_file         "${xdgState}/mpd/sticker.sql"
        db_file              "${xdgState}/mpd/database"

        auto_update          "yes"
        volume_normalization "no"
        restore_paused       "yes"
        filesystem_charset   "UTF-8"
        replaygain           "off"
        audio_buffer_size    "8192"

        audio_output {
          type       "pipewire"
          name       "PipeWire"
          format     "44100:24:2"
        }

        audio_output {
          type       "fifo"
          name       "Visualiser"
          path       "/tmp/mpd.fifo"
          format     "44100:16:2"
        }

        audio_output {
          type       "httpd"
          name       "lossless"
          encoder    "flac"
          port       "8000"
          max_clients "8"
          format     "44100:16:2"
        }

        bind_to_address "127.0.0.1"
        port            "6600"
      '';
    };

    systemd.user.services = {
      mpd = {
        description = "Music Player Daemon (User Service)";
        after = [
          "pipewire.service"
          "pipewire-pulse.service"
        ];
        wants = [ "pipewire.service" ];
        wantedBy = [ "default.target" ];
        serviceConfig = {
          ExecStart = "${getExe pkgs.mpd} --no-daemon ${xdgConfig}/mpd/mpd.conf";
          Restart = "on-failure";
        };
      };

      mpdris2 = {
        description = "MPD D-Bus Interface (mpDris2)";
        after = [ "mpd.service" ];
        wants = [ "mpd.service" ];
        wantedBy = [ "default.target" ];
        serviceConfig = {
          ExecStart = getExe pkgs.mpdris2;
          Restart = "on-failure";
        };
      };
    };
  };
}
