{ pkgs, config, ... }:

let
  python = pkgs.python3;

  bluetoothPairScript = pkgs.writeScriptBin "bluetooth-pair" ''
    #!${python}/bin/python3
    import errno
    import os
    import pty
    import select
    import subprocess
    import sys
    import time

    def log(msg):
        sys.stdout.write(f"[bluetooth-pair] {msg}\n")
        sys.stdout.flush()

    if len(sys.argv) < 2:
        log("Usage: bluetooth-pair.py <addr>")
        sys.exit(1)

    addr = sys.argv[1]

    if not addr or len(addr) < 17:
        log(f"Invalid Bluetooth address: '{addr}'")
        sys.exit(1)

    mfd, sfd = pty.openpty()
    subprocess.Popen(['bluetoothctl'], stdin=sfd, stdout=sfd, stderr=sfd, close_fds=True)
    os.close(sfd)

    def send_cmd(cmd):
        log(f"Sending: {cmd}")
        os.write(mfd, (cmd + "\n").encode('utf-8'))

    def read_output(timeout=2.0):
        output = b""
        end_time = time.time() + timeout
        while time.time() < end_time:
            r, _, _ = select.select([mfd], [], [], 0.1)
            if mfd in r:
                try:
                    data = os.read(mfd, 1024)
                    if not data:
                        break
                    output += data
                except OSError as e:
                    if e.errno == errno.EIO:
                        break
                    raise
        return output.decode('utf-8', errors='replace')

    log(f"Starting pairing with {addr}...")
    time.sleep(1)

    send_cmd("agent on")
    send_cmd("default-agent")
    time.sleep(0.5)

    send_cmd(f"pair {addr}")

    start_time = time.time()
    pair_timeout = 60

    log("Waiting for pairing...")
    while time.time() - start_time < pair_timeout:
        out = read_output(timeout=1.0)
        if out:
            log(f"Output: {out[:200]}...")
            
            if "Pairing successful" in out or "Paired: yes" in out:
                log("Pairing successful!")
                send_cmd(f"trust {addr}")
                time.sleep(0.5)
                send_cmd(f"connect {addr}")
                time.sleep(2)
                send_cmd("quit")
                sys.exit(0)
            
            if "Failed to pair" in out:
                log("Pairing failed")
                send_cmd("quit")
                sys.exit(1)
            
            if "Confirm passkey" in out or "yes/no" in out or "Request confirmation" in out:
                log("Sending confirmation...")
                send_cmd("yes")
            
            if "Enter passkey" in out or "Enter PIN" in out:
                log("PIN required - waiting for user input")
                print("PIN_REQUIRED")
                sys.stdout.flush()
                try:
                    user_pin = sys.stdin.readline().strip()
                    if user_pin:
                        log(f"Received PIN: {user_pin}")
                        send_cmd(user_pin)
                except:
                    break

    log("Pairing timed out")
    send_cmd("quit")
    sys.exit(1)
  '';

  bluetoothAgent = pkgs.writeScriptBin "bluetooth-agent" ''
    #${
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
    import sys

    BUS_NAME = 'org.bluez'
    AGENT_INTERFACE = 'org.bluez.Agent1'
    AGENT_PATH = '/org/bluez/agent'
    LOCK_FILE = "/tmp/QsAnyModuleIsOpen"

    def log(msg):
        print(f"[bluetooth-agent] {msg}", file=sys.stderr)
        sys.stderr.flush()

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
        def Release(self):
            log("Agent released")
            pass

        @dbus.service.method(AGENT_INTERFACE, in_signature="os", out_signature="")
        def AuthorizeService(self, device, uuid):
            log(f"AuthorizeService: {device} {uuid}")
            return

        @dbus.service.method(AGENT_INTERFACE, in_signature="o", out_signature="s")
        def RequestPinCode(self, device):
            log(f"RequestPinCode for {device}")
            close_quick_settings()
            try:
                output = subprocess.check_output([
                    "kdialog", "--title", "Bluetooth", "--inputbox", "Enter the device PIN:"
                ], timeout=30)
                pin = output.decode().strip()
                log(f"Returning PIN: {pin}")
                return pin
            except subprocess.TimeoutExpired:
                log("PIN entry timed out")
            except Exception as e:
                log(f"PIN entry error: {e}")
            raise dbus.exceptions.DBusException("Rejected", name="org.bluez.Error.Rejected")

        @dbus.service.method(AGENT_INTERFACE, in_signature="ou", out_signature="")
        def RequestConfirmation(self, device, passkey):
            log(f"RequestConfirmation for {device}: {passkey:06d}")
            close_quick_settings()
            try:
                result = subprocess.check_call([
                    "kdialog", "--title", "Bluetooth Pairing", "--yesno",
                    f"Device wants to pair.\nPIN: {passkey:06d}\nConfirm?"
                ], timeout=30)
                log(f"Confirmation result: {result}")
            except subprocess.TimeoutExpired:
                log("Confirmation timed out")
            except Exception as e:
                log(f"Confirmation error: {e}")
                raise dbus.exceptions.DBusException("Rejected", name="org.bluez.Error.Rejected")

        @dbus.service.method(AGENT_INTERFACE, in_signature="o", out_signature="")
        def RequestAuthorization(self, device):
            log(f"RequestAuthorization for {device}")
            close_quick_settings()
            try:
                subprocess.check_call([
                    "kdialog", "--title", "Bluetooth", "--yesno",
                    "Authorize pairing with this device?"
                ], timeout=30)
            except subprocess.TimeoutExpired:
                log("Authorization timed out")
            except Exception as e:
                log(f"Authorization error: {e}")
                raise dbus.exceptions.DBusException("Rejected", name="org.bluez.Error.Rejected")

        @dbus.service.method(AGENT_INTERFACE, in_signature="", out_signature="")
        def Cancel(self):
            log("Pairing cancelled")
            pass

    if __name__ == '__main__':
        log("Starting Bluetooth agent...")
        dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
        bus = dbus.SystemBus()
        
        try:
            agent = Agent(bus, AGENT_PATH)
            log("Agent object created")
            
            obj = bus.get_object(BUS_NAME, "/org/bluez")
            manager = dbus.Interface(obj, "org.bluez.AgentManager1")
            
            manager.RegisterAgent(AGENT_PATH, "KeyboardDisplay")
            log("Agent registered with NoInputNoOutput capability")
            
            manager.RequestDefaultAgent(AGENT_PATH)
            log("Agent set as default")
            
        except Exception as e:
            log(f"Error setting up agent: {e}")
            import traceback
            traceback.print_exc()

        log("Bluetooth agent running...")
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
      kdePackages.kdialog
      wtype
      bluetoothAgent
      bluetoothPairScript
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
      "dbus.service"
    ];
    requires = [
      "bluetooth.service"
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

  services.blueman.enable = false;

  system.stateVersion = "25.11";
}
