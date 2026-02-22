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
        sys.stdout.write(f"[pair] {msg}\n")
        sys.stdout.flush()

    if len(sys.argv) < 5:
        log("Usage: bluetooth-pair.py <addr> <pairWaitSeconds> <attempts> <intervalSec>")
        sys.exit(2)

    addr = sys.argv[1]
    pair_wait_seconds = float(sys.argv[2])
    if pair_wait_seconds < 30:
        pair_wait_seconds = 45.0
    attempts = int(sys.argv[3])
    interval_sec = float(sys.argv[4])

    if not addr or len(addr) < 17:
        log(f"Invalid Bluetooth address: '{addr}'")
        sys.exit(2)

    mfd, sfd = pty.openpty()
    subprocess.Popen(['bluetoothctl'], stdin=sfd, stdout=sfd, stderr=sfd, close_fds=True)
    os.close(sfd)

    def send_cmd(cmd):
        log(f"Sending cmd: {cmd}")
        os.write(mfd, (cmd + "\n").encode('utf-8'))

    def read_output(timeout=1.0):
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

    log("Initializing bluetoothctl...")
    time.sleep(1)

    send_cmd("agent on")
    send_cmd("default-agent")
    time.sleep(1)

    log(f"Attempting to pair with {addr}...")

    # First, make sure adapter is powered on and scanning
    send_cmd("power on")
    time.sleep(0.5)
    send_cmd("discoverable on")
    time.sleep(0.5)
    send_cmd("scan on")
    time.sleep(2)

    # Just try to pair directly
    send_cmd(f"pair {addr}")

    start_time = time.time()
    paired = False

    log("Waiting for pairing sequence start...")
    while time.time() - start_time < pair_wait_seconds:
        out = read_output(timeout=1.0)
        if out:
            sys.stdout.write(out)
            
            if f"Device {addr} not available" in out:
                log(f"Device {addr} not discovered yet, waiting longer...")
                pair_wait_seconds += 10

            if "Confirm passkey" in out or "yes/no" in out or "Request confirmation" in out:
                log("Passkey confirmation detected - user already confirmed on phone, confirming here")
                send_cmd("yes")

            if "Authorize service" in out or "Request authorization" in out:
                log("Authorization request detected - confirming")
                send_cmd("yes")

            if "Enter passkey" in out or "Enter PIN code" in out or "Passkey: " in out:
                log("Device requested PIN/Passkey. Waiting for user input...")
                log("PIN_REQUIRED")
                try:
                    user_pin = sys.stdin.readline().strip()
                    if user_pin:
                        log(f"Received PIN: {user_pin}, relaying to bluetoothctl...")
                        send_cmd(user_pin)
                except Exception as e:
                    log(f"Error reading stdin: {e}")
                    break

            if "Pairing successful" in out or "Paired: yes" in out or "Bonded: yes" in out:
                paired = True
                log("Pairing successful detected in stream.")
                break

            if "AlreadyExists" in out:
                log("Device already paired on laptop, removing and re-pairing...")
                send_cmd(f"remove {addr}")
                time.sleep(2)
                send_cmd("scan on")
                time.sleep(3)
                send_cmd(f"pair {addr}")
                continue

            if "Failed to pair" in out:
                log("Pairing failed explicitly.")
                break
            
            if "Already joined" in out or "Already exists" in out:
                paired = True
                log("Device already paired.")
                break
        
        # Also check if the process is still in the pairing state
        time.sleep(0.5)

    if not paired:
        send_cmd(f"info {addr}")
        time.sleep(1)
        out = read_output(timeout=1)
        if "Paired: yes" in out:
            paired = True

    if paired:
        log("Device is paired. Trusting...")
        send_cmd(f"trust {addr}")
        time.sleep(1)

        log("Connecting...")
        connected = False
        for i in range(attempts):
            send_cmd(f"connect {addr}")
            time.sleep(interval_sec)

            send_cmd(f"info {addr}")
            time.sleep(1)
            out = read_output(timeout=1)
            if "Connected: yes" in out:
                log("Connected successfully, we are done here.")
                connected = True
                break
            else:
                log(f"Connection attempt {i + 1}/{attempts} failed. Retrying...")

        if connected:
            send_cmd("quit")
            sys.exit(0)
        else:
            log("Failed to connect after all attempts.")
            send_cmd("quit")
            sys.exit(1)
    else:
        log("Failed to pair within timeout.")
        send_cmd("quit")
        sys.exit(1)
  '';

  # bluetoothAgent disabled - using script only
  bluetoothAgent = null;
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
      python3
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

  # systemd.user.services.bluetooth-agent = {
  #   description = "Bluetooth Pairing Agent for Quickshell";
  #   after = [
  #     "bluetooth.service"
  #     "dbus.service"
  #   ];
  #   requires = [
  #     "bluetooth.service"
  #   ];
  #   wantedBy = [ "graphical-session.target" ];
  #   serviceConfig = {
  #     Type = "simple";
  #     ExecStart = "${bluetoothAgent}/bin/bluetooth-agent";
  #     Restart = "always";
  #     RestartSec = 3;
  #     StandardOutput = "journal+console";
  #     StandardError = "journal+console";
  #     TimeoutStartSec = 30;
  #   };
  # };

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
