{ pkgs, config, ... }:

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

  environment.pathsToLink = [ "/share/icons" ];

  services = {
    dbus = {
      enable = true;
      packages = [ pkgs.dconf ];
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

  hardware.bluetooth.enable = true;

  system.stateVersion = "25.11";
}
