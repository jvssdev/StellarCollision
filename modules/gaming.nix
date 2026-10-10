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
    ;
  cfg = config.cfg.gaming;

  edenFixed = pkgs.symlinkJoin {
    name = "eden-fixed";
    paths = [ pkgs.eden ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/eden \
        --set GSETTINGS_SCHEMA_DIR "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas" \
        --set QT_QPA_PLATFORM xcb \
        --add-flags "-platform xcb"
    '';
  };

  # lutrisPackage = pkgs.lutris.override {
  #   extraLibraries = _: [ pkgs.wineWow64Packages.staging ];
  # };

  shareCfg = cfg.waydroidEdenShare;
  hostUser = config.cfg.vars.username;
  hostGroup = config.users.users.${hostUser}.group;
  waydroidMedia = "${config.cfg.vars.homeDirectory}/.local/share/waydroid/data/media/0";
  syncParent = "${waydroidMedia}/${shareCfg.waydroidDir}";
  syncTarget = "${syncParent}/nand";
  syncSource = "${shareCfg.edenDir}/nand";

  waydroidEdenSync = pkgs.writeShellApplication {
    name = "waydroid-eden-sync";
    runtimeInputs = with pkgs; [
      coreutils
      util-linux
      rsync
    ];
    text = ''
      if [[ ! -d "${syncSource}" ]]; then
        echo "Eden nand not found at ${syncSource}" >&2
        exit 0
      fi

      if [[ ! -d "${waydroidMedia}" ]]; then
        echo "Waydroid media not found at ${waydroidMedia}" >&2
        exit 0
      fi

      if mountpoint -q "${syncTarget}"; then
        echo "Bind mount still active on ${syncTarget}; unmount it first" >&2
        exit 1
      fi

      install -d -m 2775 -o 1023 -g 1023 "${syncParent}" "${syncTarget}"

      rsync -au --chown=${hostUser}:${hostGroup} --chmod=D755,F644 "${syncTarget}/" "${syncSource}/"
      rsync -au --chown=1023:1023 --chmod=D2775,F664 "${syncSource}/" "${syncTarget}/"
    '';
  };
in
{
  options.cfg.gaming = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable gaming configuration.";
    };

    waydroidEdenShare = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Keep Eden nand synced with Waydroid shared storage.";
      };

      edenDir = mkOption {
        type = types.str;
        default = "${config.cfg.vars.homeDirectory}/.local/share/eden";
        description = "Absolute host path that contains Eden nand/.";
      };

      waydroidDir = mkOption {
        type = types.str;
        default = "Download/eden";
        description = "Folder inside Waydroid internal storage that receives nand/.";
      };

      syncIntervalSec = mkOption {
        type = types.int;
        default = 60;
        description = "How often to sync in both directions (seconds).";
      };
    };
  };

  config = mkIf cfg.enable {
    hj = {
      packages = [
        edenFixed
        pkgs.azahar
        pkgs.melonds
        # lutrisPackage
        # pkgs.winetricks
      ];

      xdg.config.files = {
        "lutris/system.yml".text = ''
          system:
            env:
              DOTNET_ROOT: /dev/null
              DOTNET_BUNDLE_EXTRACT_BASE_DIR: /dev/null
        '';

        "lutris/runners/wine.yml".text = ''
          wine:
            system_winetricks: true
        '';
      };
    };

    environment.systemPackages = mkIf shareCfg.enable [ waydroidEdenSync ];

    systemd.services.waydroid-eden-sync = mkIf shareCfg.enable {
      description = "Sync Eden nand with Waydroid shared storage";
      wantedBy = [ "multi-user.target" ];
      after = [ "local-fs.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${waydroidEdenSync}/bin/waydroid-eden-sync";
      };
    };

    systemd.timers.waydroid-eden-sync = mkIf shareCfg.enable {
      description = "Periodic Eden nand sync with Waydroid";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "1min";
        OnUnitActiveSec = "${toString shareCfg.syncIntervalSec}s";
        AccuracySec = "10s";
        Unit = "waydroid-eden-sync.service";
      };
    };
  };
}
