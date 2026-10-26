package main

import (
	"context"
	"errors"
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
	if ok, err := l.close(ctx, key, id); err != nil || ok {
		t.Fatal("pending upload attested")
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
}
