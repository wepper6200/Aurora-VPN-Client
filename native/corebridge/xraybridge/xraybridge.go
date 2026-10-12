// Package xraybridge runs Xray-core next to sing-box's libbox inside the
// Android app. It is bound together with libbox by gomobile into a single
// native library (two separate gomobile AARs cannot coexist in one APK).
//
// sing-box owns the TUN, DNS and routing; Xray only serves an authenticated
// SOCKS inbound on 127.0.0.1 that sing-box forwards to for servers that need
// Xray-only features (XHTTP, VLESS encryption, mux…).
package xraybridge

import (
	"strings"
	"sync"

	"github.com/xtls/xray-core/core"
	"github.com/xtls/xray-core/infra/conf/serial"

	// Registers all Xray protocols, transports and the JSON loader.
	_ "github.com/xtls/xray-core/main/distro/all"
)

var (
	mu       sync.Mutex
	instance *core.Instance
)

// Start launches Xray with the given JSON config, replacing any running one.
func Start(configJSON string) error {
	mu.Lock()
	defer mu.Unlock()
	stopLocked()
	config, err := serial.LoadJSONConfig(strings.NewReader(configJSON))
	if err != nil {
		return err
	}
	server, err := core.New(config)
	if err != nil {
		return err
	}
	if err := server.Start(); err != nil {
		server.Close()
		return err
	}
	instance = server
	return nil
}

// Stop shuts Xray down; a no-op when it isn't running.
func Stop() error {
	mu.Lock()
	defer mu.Unlock()
	return stopLocked()
}

func stopLocked() error {
	if instance == nil {
		return nil
	}
	err := instance.Close()
	instance = nil
	return err
}

// Check validates a config without starting it.
func Check(configJSON string) error {
	config, err := serial.LoadJSONConfig(strings.NewReader(configJSON))
	if err != nil {
		return err
	}
	_, err = core.New(config)
	return err
}

// Version reports the bundled Xray-core version.
func Version() string {
	return core.Version()
}
