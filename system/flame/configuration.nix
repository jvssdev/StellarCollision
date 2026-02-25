{
  pkgs,
  config,
  lib,
  ...
}:

let
  inherit (lib) getExe getExe';
  bluetooth-scripts = pkgs.callPackage ./scripts { };
  bluetooth-agent = pkgs.callPackage ./bluetooth-agent { };
in

{
  imports = [ ./hardware-configuration.nix ];

  cfg = {
    drivers.intel.enable = true;
    mango.enable = false;
    niri.enable = true;
    quickshell.enable = true;
    sessionVariables.enable = true;
    portals.enable = true;
    ghostty.enable = false;
    wezterm.enable = true;
    zsh.enable = true;
    nvf.enable = true;
    opencode.enable = true;
    zen-browser.enable = true;
    helium.enable = true;
    zed.enable = true;
    keyring.enable = true;
    git.enable = true;
    fonts.enable = true;
    gtk.enable = true;
    qt.enable = true;
    dunst.enable = false;
    fuzzel.enable = true;
    btop.enable = true;
    zathura.enable = true;
    keepassxc.enable = true;
    gammastep.enable = true;
    wpaperd.enable = false;
    locale.enable = true;
    editorPackages.enable = true;
    yazi.enable = true;
    sddm.enable = true;
    virtualisation.enable = true;
    jujutsu = {
      enable = true;
      integrations.difftastic.enable = true;
    };
    mpd.enable = true;
    rmpc.enable = true;

    vars = {
      withGui = true;
      isALaptop = true;
    };
  };

  powerManagement = {
    powertop.enable = true;
  };

  programs = {
    dconf.enable = true;
    xwayland.enable = true;
    kdeconnect.enable = true;
  };

  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 20;
        consoleMode = "auto";
      };
      efi.canTouchEfiVariables = true;
      timeout = 10;
    };
    kernelPackages = pkgs.linuxPackages_latest;
  };

  networking = {
    hostName = "flame";
    networkmanager.enable = true;
  };

  environment = {
    pathsToLink = [ "/share/icons" ];
    systemPackages = with pkgs; [
      kdePackages.kdialog
      wtype
      bluetooth-scripts.bluetooth-pair
      bluetooth-agent
      upower
      python3
    ];
  };

  services = {
    dbus = {
      enable = true;
      packages = [ pkgs.dconf ];
    };
    upower = {
      enable = true;
    };
    auto-cpufreq = {
      enable = true;
      settings = {
        battery = {
          governor = "powersave";
          turbo = "never";
        };
        charger = {
          governor = "performance";
          turbo = "auto";
        };
      };
    };

    logind = {
      settings = {
        Login = {
          HandlePowerKey = "suspend";
          HandlePowerKeyLongPress = "poweroff";
          HandleLidSwitch = "suspend";
          HandleLidSwitchExternalPower = "suspend";
          HandleLidSwitchDocked = "ignore";
        };
      };
    };

    syncthing = {
      enable = true;
      user = "${config.cfg.vars.username}";
      dataDir = "/home/${config.cfg.vars.username}";
    };

    power-profiles-daemon.enable = false;

    pulseaudio.enable = false;

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };

  systemd.user.services.bluetooth-agent = {
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${lib.getExe bluetooth-agent}";
      Restart = "always";
      RestartSec = "3";
    };
  };

  hardware.bluetooth = {
    enable = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
        PairableTimeout = 0;
      };
    };
  };

  services.blueman.enable = false;

  system.stateVersion = "25.11";
}
