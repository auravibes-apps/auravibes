package main

import (
	"context"
	"errors"
	"fmt"
	"os"
	"testing"

	"github.com/jackc/pgx/v5/pgxpool"
)

// The URL must identify a disposable database dedicated to this test.
func TestPostgresFencePersistsUnknownWrites(t *testing.T) {
	dsn := os.Getenv("GATEWAY_TEST_DATABASE_URL")
	if dsn == "" {
		t.Skip("set GATEWAY_TEST_DATABASE_URL to a disposable PostgreSQL database")
	}
	ctx := context.Background()
	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		t.Fatal("open test database failed")
	}
	defer pool.Close()
	schema, err := os.ReadFile("schema.sql")
	if err != nil {
		t.Fatal(err)
	}
	if _, err = pool.Exec(ctx, string(schema)); err != nil {
		t.Fatal("test schema setup failed")
	}
	l := &postgresLedger{pool: pool}
	key := "1/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
	id := "a"
	if ok, err := l.close(ctx, key, id); ok || !errors.Is(err, errUnknown) {
		t.Fatal("unknown key attested")
	}
	if err = l.register(ctx, key, id); err != nil {
		t.Fatal(err)
	}
	if err = l.register(ctx, key, id); err != nil {
		t.Fatal("registration replay failed")
	}
	if err = l.register(ctx, key, "different"); !errors.Is(err, errReplay) {
		t.Fatal("provenance replaced")
	}
	if err = l.start(ctx, key, id, "reservation"); err != nil {
		t.Fatal(err)
	}
	if closed, pending, err := l.status(ctx, key, id); err != nil || closed || pending != 1 {
		t.Fatal("status did not report the open pending reservation")
	}
	if _, _, err := l.status(ctx, key, "wrong"); !errors.Is(err, errUnknown) {
		t.Fatal("status accepted a different registration")
	}
	if ok, err := l.close(ctx, key, id); err != nil || ok {
		t.Fatal("pending upload attested")
	}
	if closed, pending, err := l.status(ctx, key, id); err != nil || !closed || pending != 1 {
		t.Fatal("status did not report the closed pending reservation")
	}
	restarted := &postgresLedger{pool: pool}
	if err = restarted.start(ctx, key, id, "later"); !errors.Is(err, errClosed) {
		t.Fatal("closed key accepted upload")
	}
	if ok, err := restarted.close(ctx, key, id); err != nil || ok {
		t.Fatal("pending upload lost on restart")
	}
	if err = restarted.finish(ctx, key, "reservation"); err != nil {
		t.Fatal(err)
	}
	if ok, err := restarted.close(ctx, key, id); err != nil || !ok {
		t.Fatal("completed upload not drained")
	}
	// Separate pool transactions race admission against closure. Exactly one
	// ordering must win: an admitted operation blocks proof, or closure rejects it.
	for i := 0; i < 40; i++ {
		raceKey := fmt.Sprintf("race-%d", i)
		if err = l.register(ctx, raceKey, id); err != nil {
			t.Fatal(err)
		}
		startGate := make(chan struct{})
		admission := make(chan error, 1)
		closed := make(chan bool, 1)
		closeErr := make(chan error, 1)
		go func() { <-startGate; admission <- l.start(ctx, raceKey, id, raceKey) }()
		go func() { <-startGate; ok, e := l.close(ctx, raceKey, id); closed <- ok; closeErr <- e }()
		close(startGate)
		startErr := <-admission
		ready := <-closed
		if e := <-closeErr; e != nil {
			t.Fatal(e)
		}
		if startErr == nil && ready {
			t.Fatal("admitted operation was not drained")
		}
		if startErr != nil && (!errors.Is(startErr, errClosed) || !ready) {
			t.Fatalf("unexpected linearization: %v %v", startErr, ready)
		}
	}

}
