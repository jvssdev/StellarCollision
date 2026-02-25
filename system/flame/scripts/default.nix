{ pkgs, lib, ... }:

let
  inherit (pkgs) writeScriptBin;
in
{
  bluetooth-agent = writeScriptBin "bluetooth-agent" /* python */ ''
        #!${pkgs.python3}/bin/python3
        import os
        import sys
        import logging
        import subprocess

        logging.basicConfig(
            level=logging.DEBUG,
            format='%(asctime)s [bluetooth-agent] %(levelname)s: %(message)s',
            handlers=[
                logging.FileHandler('/tmp/bluetooth-agent.log'),
                logging.StreamHandler(sys.stderr)
            ]
        )
        logger = logging.getLogger(__name__)

        AGENT_PATH = "/stellar/agent"
        AGENT_INTERFACE = "org.bluez.Agent1"
        INTROSPECT_INTERFACE = "org.freedesktop.DBus.Introspectable"

        INTROSPECT_XML = """
    <node>
        <interface name="org.bluez.Agent1">
            <method name="Release"/>
            <method name="RequestPinCode">
                <arg direction="in" type="o" name="device"/>
                <arg direction="out" type="s" name="pincode"/>
            </method>
            <method name="RequestPasskey">
                <arg direction="in" type="o" name="device"/>
                <arg direction="out" type="u" name="passkey"/>
            </method>
            <method name="DisplayPinCode">
                <arg direction="in" type="o" name="device"/>
                <arg direction="in" type="s" name="pincode"/>
            </method>
            <method name="DisplayPasskey">
                <arg direction="in" type="o" name="device"/>
                <arg direction="in" type="u" name="passkey"/>
                <arg direction="in" type="q" name="entered"/>
            </method>
            <method name="RequestConfirmation">
                <arg direction="in" type="o" name="device"/>
                <arg direction="in" type="u" name="passkey"/>
            </method>
            <method name="RequestAuthorization">
                <arg direction="in" type="o" name="device"/>
            </method>
            <method name="AuthorizeService">
                <arg direction="in" type="o" name="device"/>
                <arg direction="in" type="s" name="uuid"/>
            </method>
            <method name="Cancel"/>
        </interface>
        <interface name="org.freedesktop.DBus.Introspectable">
            <method name="Introspect">
                <arg direction="out" type="s" name="data"/>
            </method>
        </interface>
    </node>
    """

        def notify(title, message, timeout=30000):
            try:
                subprocess.run(
                    ["notify-send", "-u", "critical", "-p", "-t", str(timeout),
                     title, message],
                    capture_output=True, timeout=5
                )
            except Exception as e:
                logger.debug(f"Notification error: {e}")

        class Rejected(Exception):
            _dbus_error_name = "org.bluez.Error.Rejected"

        class Agent:
            def __init__(self, bus, path):
                import dbus.service
                self.bus = bus
                self.path = path
                dbus.service.Object.__init__(self, bus, path)

            @dbus.service.method(AGENT_INTERFACE, in_signature="", out_signature="")
            def Release(self):
                logger.info("Agent released")

            @dbus.service.method(AGENT_INTERFACE, in_signature="o", out_signature="s")
            def RequestPinCode(self, device):
                logger.info(f"RequestPinCode: {device}")
                notify("Bluetooth Pairing", "Enter PIN code on device")
                return "0000"

            @dbus.service.method(AGENT_INTERFACE, in_signature="o", out_signature="u")
            def RequestPasskey(self, device):
                logger.info(f"RequestPasskey: {device}")
                notify("Bluetooth Pairing", "Enter passkey on device")
                return dbus.UInt32(0)

            @dbus.service.method(AGENT_INTERFACE, in_signature="ous", out_signature="")
            def DisplayPinCode(self, device, pincode):
                logger.info(f"DisplayPinCode: {device} {pincode}")
                notify("Bluetooth PIN", f"PIN: {pincode}")

            @dbus.service.method(AGENT_INTERFACE, in_signature="ouq", out_signature="")
            def DisplayPasskey(self, device, passkey, entered):
                logger.info(f"DisplayPasskey: {device} {passkey:06d} entered {entered}")
                if entered == 0:
                    notify("Bluetooth Passkey", f"Passkey: {passkey:06d}")

            @dbus.service.method(AGENT_INTERFACE, in_signature="ou", out_signature="")
            def RequestConfirmation(self, device, passkey):
                logger.info(f"RequestConfirmation: {device} {passkey:06d}")
                notify("Bluetooth Pairing", f"Confirm passkey: {passkey:06d}\nAuto-confirming...")
                pass

            @dbus.service.method(AGENT_INTERFACE, in_signature="o", out_signature="")
            def RequestAuthorization(self, device):
                logger.info(f"RequestAuthorization: {device}")
                notify("Bluetooth Authorization", "Authorizing connection...")
                pass

            @dbus.service.method(AGENT_INTERFACE, in_signature="o", out_signature="")
            def Authorize(self, device, uuid):
                logger.info(f"Authorize: {device} {uuid}")
                notify("Bluetooth Service", f"Authorize service: {uuid}")
                pass

            @dbus.service.method(AGENT_INTERFACE, in_signature="", out_signature="")
            def Cancel(self):
                logger.info("Cancel")

            @dbus.service.method(INTROSPECT_INTERFACE, in_signature="", out_signature="s")
            def Introspect(self):
                return INTROSPECT_XML

        if __name__ == "__main__":
            import dbus
            import dbus.service
            from dbus.mainloop.glib import DBusGMainLoop
            from gi.repository import GObject as gobject

            try:
                logger.info("Starting Bluetooth agent...")

                DBusGMainLoop(set_as_default=True)
                bus = dbus.SystemBus()

                agent = Agent(bus, AGENT_PATH)

                obj = bus.get_object("org.bluez", "/org/bluez")
                manager = dbus.Interface(obj, "org.bluez.AgentManager1")

                logger.info("Registering agent with BlueZ...")
                manager.RegisterAgent(AGENT_PATH, "KeyboardDisplay")
                manager.RequestDefaultAgent(AGENT_PATH)

                logger.info("Agent registered successfully, waiting for pairing requests...")
                notify("Bluetooth Agent", "Agent started and ready for pairing")

                mainloop = gobject.MainLoop()
                mainloop.run()

            except KeyboardInterrupt:
                logger.info("Agent stopped by user")
            except Exception as e:
                logger.exception(f"Failed to start agent: {e}")
                sys.exit(1)
  '';

  bluetooth-pair = writeScriptBin "bluetooth-pair" /* python */ ''
    #!${pkgs.python3}/bin/python3
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

    send_cmd("power on")
    time.sleep(0.5)
    send_cmd("discoverable on")
    time.sleep(0.5)
    send_cmd("scan on")
    time.sleep(2)

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
}
