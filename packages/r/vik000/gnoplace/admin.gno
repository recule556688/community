package gnoplace

import (
	"std"
	"time"

	"gno.land/p/nt/avl"
)

// Resets gnoplace
func Reset(_ realm) {
	if std.OriginCaller() != "g13kytw9mpyutwmyg5eq7arqxqcszfl6uq4p89zg" {
		panic("access restricted")
	}

	users = avl.NewTree()
	pixels = [300]int{}
}

func SetInterval(_ realm, interval int) {
	if std.OriginCaller() != "g13kytw9mpyutwmyg5eq7arqxqcszfl6uq4p89zg" {
		panic("access restricted")
	}

	interval_s = time.Duration(interval) * time.Second
}