package main

import (
	"fmt"
	"log"
	"os"
	"os/exec"

	"github.com/godbus/dbus/v5"
)

const (
	bluezService      = "org.bluez"
	agentManagerPath  = "/org/bluez"
	agentManagerIface = "org.bluez.AgentManager1"
	agent1Iface       = "org.bluez.Agent1"
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

func getDeviceInfo(conn *dbus.Conn, device dbus.ObjectPath) (string, string) {
	obj := conn.Object(bluezService, device)

	var name, alias, addr string

	nameVar, _ := obj.GetProperty(agent1Iface + ".Name")
	if n, ok := nameVar.Value().(string); ok {
		name = n
	}

	aliasVar, _ := obj.GetProperty(agent1Iface + ".Alias")
	if a, ok := aliasVar.Value().(string); ok {
		alias = a
	}

	addrVar, _ := obj.GetProperty(agent1Iface + ".Address")
	if a, ok := addrVar.Value().(string); ok {
		addr = a
	}

	if alias != "" {
		return alias, addr
	}
	if name != "" {
		return name, addr
	}
	return addr, addr
}

func main() {
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
