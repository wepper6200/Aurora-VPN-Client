//go:build tools

// Keeps libbox in this module's dependency graph so that gomobile can bind
// it together with xraybridge into one native library.
package corebridge

import (
	_ "github.com/sagernet/gomobile/bind"
	_ "github.com/sagernet/sing-box/experimental/libbox"
)
