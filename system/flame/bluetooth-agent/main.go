package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"os/exec"
	"strings"
	"time"

	"github.com/godbus/dbus/v5"
)

const (
	bluezService      = "org.bluez"
	agentManagerPath  = "/org/bluez"
	agentManagerIface = "org.bluez.AgentManager1"
	agent1Iface       = "org.bluez.Agent1"
	device1Iface      = "org.bluez.Device1"
	adapter1Iface     = "org.bluez.Adapter1"
	objectMgrIface    = "org.freedesktop.DBus.ObjectManager"
	propertiesIface   = "org.freedesktop.DBus.Properties"
	agentPath         = "/com/stellar/bluez/agent"
	agentCapability   = "KeyboardDisplay"
)

const introspectXML = `
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
</node>`

type Agent struct{}

func notify(title, message string) {
	cmd := exec.Command("notify-send", "-u", "critical", "-p", "-t", "30000", title, message)
	cmd.Run()
}

func (Agent) RequestPinCode(device dbus.ObjectPath) (string, *dbus.Error) {
	log.Printf("[Agent] RequestPinCode: device=%s", device)
	notify("Bluetooth Pairing", "Enter PIN code on device")
	return "0000", nil
}

func (Agent) RequestPasskey(device dbus.ObjectPath) (uint32, *dbus.Error) {
	log.Printf("[Agent] RequestPasskey: device=%s", device)
	notify("Bluetooth Pairing", "Enter passkey on device")
	return 0, nil
}

func (Agent) DisplayPinCode(device dbus.ObjectPath, pincode string) *dbus.Error {
	log.Printf("[Agent] DisplayPinCode: device=%s, pin=%s", device, pincode)
	notify("Bluetooth PIN", fmt.Sprintf("PIN: %s", pincode))
	return nil
}

func (Agent) DisplayPasskey(device dbus.ObjectPath, passkey uint32, entered uint16) *dbus.Error {
	log.Printf("[Agent] DisplayPasskey: device=%s, passkey=%06d, entered=%d", device, passkey, entered)
	if entered == 0 {
		notify("Bluetooth Passkey", fmt.Sprintf("Passkey: %06d", passkey))
	}
	return nil
}

func (Agent) RequestConfirmation(device dbus.ObjectPath, passkey uint32) *dbus.Error {
	log.Printf("[Agent] RequestConfirmation: device=%s, passkey=%06d", device, passkey)
	notify("Bluetooth Pairing", fmt.Sprintf("Confirm passkey: %06d\nAuto-confirming...", passkey))
	return nil
}

func (Agent) RequestAuthorization(device dbus.ObjectPath) *dbus.Error {
	log.Printf("[Agent] RequestAuthorization: device=%s", device)
	notify("Bluetooth Authorization", "Authorizing connection...")
	return nil
}

func (Agent) AuthorizeService(device dbus.ObjectPath, uuid string) *dbus.Error {
	log.Printf("[Agent] AuthorizeService: device=%s, uuid=%s", device, uuid)
	notify("Bluetooth Service", fmt.Sprintf("Authorize service: %s", uuid))
	return nil
}

func (Agent) Cancel() *dbus.Error {
	log.Printf("[Agent] Cancel called")
	return nil
}

func (Agent) Release() *dbus.Error {
	log.Printf("[Agent] Release called")
	return nil
}

func (Agent) Introspect() (string, *dbus.Error) {
	return introspectXML, nil
}

func findAdapter(conn *dbus.Conn) (dbus.ObjectPath, error) {
	obj := conn.Object(bluezService, dbus.ObjectPath("/"))
	var objects map[dbus.ObjectPath]map[string]map[string]dbus.Variant

	err := obj.Call(objectMgrIface+".GetManagedObjects", 0).Store(&objects)
	if err != nil {
		return "", fmt.Errorf("GetManagedObjects failed: %w", err)
	}

	for path, interfaces := range objects {
		if _, ok := interfaces[adapter1Iface]; ok {
			log.Printf("[Bluez] found adapter: %s", path)
			return path, nil
		}
	}

	return "", fmt.Errorf("no adapter found")
}

func findDevicePath(conn *dbus.Conn, adapterPath dbus.ObjectPath, addr string) (dbus.ObjectPath, error) {
	obj := conn.Object(bluezService, dbus.ObjectPath("/"))
	var objects map[dbus.ObjectPath]map[string]map[string]dbus.Variant

	err := obj.Call(objectMgrIface+".GetManagedObjects", 0).Store(&objects)
	if err != nil {
		return "", err
	}

	addrUpper := strings.ToUpper(addr)
	for path, interfaces := range objects {
		if _, ok := interfaces[device1Iface]; ok {
			if strings.HasPrefix(string(path), string(adapterPath)+"/") {
				devProps := interfaces[device1Iface]
				if devAddr, ok := devProps["Address"]; ok {
					if strings.ToUpper(devAddr.Value().(string)) == addrUpper {
						return path, nil
					}
				}
			}
		}
	}

	return "", fmt.Errorf("device not found")
}

func pairAndConnect(conn *dbus.Conn, adapterPath dbus.ObjectPath, devicePath dbus.ObjectPath) error {
	deviceObj := conn.Object(bluezService, devicePath)

	log.Printf("[Bluez] Starting pairing with %s", devicePath)
	err := deviceObj.Call(device1Iface+".Pair", 0).Err
	if err != nil {
		errStr := err.Error()
		if strings.Contains(errStr, "AlreadyPaired") || strings.Contains(errStr, "AlreadyExists") {
			log.Printf("[Bluez] Device already exists, checking if connected...")

			trustedErr := conn.Object(bluezService, devicePath).Call(propertiesIface+".Set", 0, device1Iface, "Trusted", dbus.MakeVariant(true)).Err
			if trustedErr != nil {
				log.Printf("[Bluez] Trust failed: %v", trustedErr)
			}

			connErr := deviceObj.Call(device1Iface+".Connect", 0).Err
			if connErr != nil {
				log.Printf("[Bluez] Connect failed: %v, trying to remove and re-pair...", connErr)
				adapterObj := conn.Object(bluezService, adapterPath)
				if remErr := adapterObj.Call(adapter1Iface+".RemoveDevice", 0, devicePath).Err; remErr != nil {
					log.Printf("[Bluez] Remove device failed: %v", remErr)
				}
				time.Sleep(1 * time.Second)
				return fmt.Errorf("device removed, please try pairing again")
			}
			log.Printf("[Bluez] Already paired, connected successfully!")
			return nil
		} else {
			return fmt.Errorf("pair failed: %w", err)
		}
	}

	time.Sleep(500 * time.Millisecond)

	log.Printf("[Bluez] Trusting device...")
	trustErr := conn.Object(bluezService, devicePath).Call(propertiesIface+".Set", 0, device1Iface, "Trusted", dbus.MakeVariant(true)).Err
	if trustErr != nil {
		log.Printf("[Bluez] Trust failed: %v", trustErr)
	}

	log.Printf("[Bluez] Connecting to device...")
	err = deviceObj.Call(device1Iface+".Connect", 0).Err
	if err != nil {
		return fmt.Errorf("connect failed: %w", err)
	}

	log.Printf("[Bluez] Successfully connected!")
	return nil
}

func runPair(addr string, pairWait float64, attempts int, interval float64) {
	log.Printf("Starting bluetooth-pair for %s", addr)

	conn, err := dbus.ConnectSystemBus()
	if err != nil {
		log.Printf("Failed to connect to D-Bus: %v", err)
		notify("Bluetooth Pairing", "Failed to pair with device")
		os.Exit(1)
	}
	defer conn.Close()

	adapterPath, err := findAdapter(conn)
	if err != nil {
		log.Printf("Failed to find adapter: %v", err)
		notify("Bluetooth Pairing", "No Bluetooth adapter found")
		os.Exit(1)
	}

	devicePath, err := findDevicePath(conn, adapterPath, addr)
	if err != nil {
		log.Printf("Device not found: %v", err)
		log.Printf("Scanning for devices...")

		adapterObj := conn.Object(bluezService, adapterPath)
		if err := adapterObj.Call(adapter1Iface+".StartDiscovery", 0).Err; err != nil {
			log.Printf("Failed to start discovery: %v", err)
		}

		for i := 0; i < 30; i++ {
			time.Sleep(1 * time.Second)
			devicePath, err = findDevicePath(conn, adapterPath, addr)
			if err == nil {
				break
			}
			log.Printf("Waiting for device... (%d/30)", i+1)
		}

		adapterObj.Call(adapter1Iface+".StopDiscovery", 0)

		if devicePath == "" {
			log.Printf("Device not found after scanning")
			notify("Bluetooth Pairing", "Device not found")
			os.Exit(1)
		}
	}

	if err := pairAndConnect(conn, adapterPath, devicePath); err != nil {
		log.Printf("Pairing/connection failed: %v", err)
		notify("Bluetooth Pairing", fmt.Sprintf("Failed: %v", err))
		os.Exit(1)
	}

	log.Printf("Device paired and connected successfully!")
	notify("Bluetooth", "Device connected successfully")
}

func runAgent() {
	log.SetFlags(log.LstdFlags | log.Lshortfile)
	log.SetOutput(os.Stderr)

	conn, err := dbus.ConnectSystemBus()
	if err != nil {
		log.Fatalf("Failed to connect to system bus: %v", err)
	}
	defer conn.Close()

	if err := conn.Export(Agent{}, dbus.ObjectPath(agentPath), agent1Iface); err != nil {
		log.Fatalf("Failed to export agent: %v", err)
	}

	if err := conn.Export(Agent{}, dbus.ObjectPath(agentPath), "org.freedesktop.DBus.Introspectable"); err != nil {
		log.Fatalf("Failed to export introspection: %v", err)
	}

	mgr := conn.Object(bluezService, dbus.ObjectPath(agentManagerPath))
	if err := mgr.Call(agentManagerIface+".RegisterAgent", 0, dbus.ObjectPath(agentPath), agentCapability).Err; err != nil {
		log.Fatalf("Failed to register agent: %v", err)
	}

	if err := mgr.Call(agentManagerIface+".RequestDefaultAgent", 0, dbus.ObjectPath(agentPath)).Err; err != nil {
		log.Printf("Warning: Failed to set as default agent: %v", err)
	}

	log.Printf("Agent registered at %s with capability %s", agentPath, agentCapability)
	notify("Bluetooth Agent", "Agent started and ready for pairing")

	signals := make(chan *dbus.Signal)
	conn.Signal(signals)

	log.Println("Waiting for signals...")
	select {}
}

func main() {
	agentMode := flag.Bool("agent", false, "Run as Bluetooth pairing agent")
	pairMode := flag.Bool("pair", false, "Pair and connect to a device")

	addr := flag.String("addr", "", "Bluetooth address")
	pairWait := flag.Float64("pair-wait", 45, "Wait seconds for pairing")
	attempts := flag.Int("attempts", 3, "Connection attempts")
	interval := flag.Float64("interval", 2, "Retry interval seconds")

	flag.Parse()

	if *agentMode {
		runAgent()
		os.Exit(0)
	}

	if *pairMode || *addr != "" {
		if *addr == "" || len(*addr) < 17 {
			log.Printf("Usage: bluetooth-agent --pair --addr AA:BB:CC:DD:EE:FF")
			os.Exit(1)
		}
		runPair(*addr, *pairWait, *attempts, *interval)
		os.Exit(0)
	}

	log.Printf("Usage: bluetooth-agent --agent | --pair --addr AA:BB:CC:DD:EE:FF")
	os.Exit(1)
}
