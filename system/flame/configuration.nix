{ pkgs, config, ... }:

let
  bluetoothAgent = pkgs.writeScriptBin "bluetooth-agent" ''
    #!${
      pkgs.python3.withPackages (
        ps: with ps; [
          dbus-python
          pygobject3
        ]
      )
    }/bin/python3

    import dbus
    import dbus.service
    import dbus.mainloop.glib
    from gi.repository import GLib
    import subprocess
    import time
    import os

    BUS_NAME = 'org.bluez'
    AGENT_INTERFACE = 'org.bluez.Agent1'
    AGENT_PATH = '/org/bluez/agent'
    LOCK_FILE = "/tmp/QsAnyModuleIsOpen"

    def close_quick_settings():
        if os.path.exists(LOCK_FILE):
            try:
                subprocess.run(["wtype", "-k", "Escape"], stderr=subprocess.DEVNULL)
                time.sleep(0.1)
            except:
                pass

    class Agent(dbus.service.Object):
        def __init__(self, bus, path):
            dbus.service.Object.__init__(self, bus, path)

        @dbus.service.method(AGENT_INTERFACE, in_signature="", out_signature="")
        def Release(self): pass

        @dbus.service.method(AGENT_INTERFACE, in_signature="os", out_signature="")
        def AuthorizeService(self, device, uuid): return

        @dbus.service.method(AGENT_INTERFACE, in_signature="o", out_signature="s")
        def RequestPinCode(self, device):
            close_quick_settings()
            try:
                output = subprocess.check_output([
                    "zenity", "--entry",
                    "--title=Bluetooth",
                    "--text=Digite o PIN do dispositivo:",
                    "--width=350"
                ])
                return output.decode().strip()
            except:
                raise Exception("Rejected")

        @dbus.service.method(AGENT_INTERFACE, in_signature="ou", out_signature="")
        def RequestConfirmation(self, device, passkey):
            close_quick_settings()
            try:
                subprocess.check_call([
                    "zenity", "--question",
                    "--title=Bluetooth Pairing",
                    "--text=Dispositivo quer parear.\nPIN: " + f"{passkey:06d}\nConfirmar?",
                    "--ok-label=Confirmar",
                    "--cancel-label=Cancelar",
                    "--width=350"
                ])
            except:
                raise Exception("Rejected")

        @dbus.service.method(AGENT_INTERFACE, in_signature="o", out_signature="")
        def RequestAuthorization(self, device):
            close_quick_settings()
            try:
                subprocess.check_call([
                    "zenity", "--question",
                    "--title=Bluetooth",
                    "--text=Autorizar pareamento?",
                    "--ok-label=Sim",
                    "--cancel-label=Não",
                    "--width=300"
                ])
            except:
                raise Exception("Rejected")

        @dbus.service.method(AGENT_INTERFACE, in_signature="", out_signature="")
        def Cancel(self): pass

    if __name__ == '__main__':
        dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
        bus = dbus.SystemBus()
        agent = Agent(bus, AGENT_PATH)

        obj = bus.get_object(BUS_NAME, "/org/bluez")
        manager = dbus.Interface(obj, "org.bluez.AgentManager1")
        manager.RegisterAgent(AGENT_PATH, "KeyboardDisplay")
        manager.RequestDefaultAgent(AGENT_PATH)

        print("Bluetooth agent running...")
        mainloop = GLib.MainLoop()
        mainloop.run()
  '';
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
      zenity
      wtype
      bluetoothAgent
    ];
  };

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

  systemd.user.services.bluetooth-agent = {
    description = "Bluetooth Pairing Agent for Quickshell";
    after = [
      "bluetooth.service"
      "pipewire.service"
      "graphical-session-pre.target"
      "dbus.service"
    ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${bluetoothAgent}/bin/bluetooth-agent";
      Restart = "always";
      RestartSec = 3;
      StandardOutput = "journal+console";
      StandardError = "journal+console";
      TimeoutStartSec = 30;
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
  services.blueman.enable = true;

  system.stateVersion = "25.11";
}
