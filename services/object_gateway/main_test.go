package main

import (
	"net/http"
	"testing"
	"time"
)

func TestIdleTimeoutIsBoundedIndependentlyOfReadTimeout(t *testing.T) {
	server := newServer(":0", http.NotFoundHandler(), time.Hour, time.Hour)
	if server.IdleTimeout <= 0 || server.IdleTimeout > time.Minute || server.IdleTimeout >= server.ReadTimeout {
		t.Fatal("idle connections are not independently bounded")
	}
}
