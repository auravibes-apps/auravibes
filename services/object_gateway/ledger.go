package main

import (
	"context"
	"crypto/sha256"
	"errors"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

var (
	errClosed  = errors.New("key closed")
	errUnknown = errors.New("key provenance unknown")
	errReplay  = errors.New("upload already reserved")
)

// postgresLedger serializes registration, closure and upload starts on the key
// row. Reservations remain pending until the upstream write is acknowledged.
type postgresLedger struct{ pool *pgxpool.Pool }

func keyDigest(value string) []byte { sum := sha256.Sum256([]byte(value)); return sum[:] }

// register is only safe for a freshly generated key whose entire write history
// is known to belong to this gateway. Existing keys can never be registered.
func (l *postgresLedger) register(ctx context.Context, key, id string) error {
	var matches bool
	err := l.pool.QueryRow(ctx, `INSERT INTO object_gateway.keys (key_hash, registration_hash, closed) VALUES ($1, $2, false) ON CONFLICT (key_hash) DO UPDATE SET registration_hash=object_gateway.keys.registration_hash WHERE object_gateway.keys.registration_hash=EXCLUDED.registration_hash RETURNING true`, keyDigest(key), keyDigest(id)).Scan(&matches)
	if errors.Is(err, pgx.ErrNoRows) {
		return errReplay
	}
	return err
}

func (l *postgresLedger) allow(ctx context.Context, key, id string) error {
	var closed bool
	err := l.pool.QueryRow(ctx, `SELECT closed FROM object_gateway.keys WHERE key_hash=$1 AND registration_hash=$2`, keyDigest(key), keyDigest(id)).Scan(&closed)
	if errors.Is(err, pgx.ErrNoRows) {
		return errUnknown
	}
	if err != nil {
		return err
	}
	if closed {
		return errClosed
	}
	return nil
}

func (l *postgresLedger) start(ctx context.Context, key, registrationID, id string) error {
	tx, err := l.pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)
	var closed bool
	err = tx.QueryRow(ctx, `SELECT closed FROM object_gateway.keys WHERE key_hash=$1 AND registration_hash=$2 FOR UPDATE`, keyDigest(key), keyDigest(registrationID)).Scan(&closed)
	if errors.Is(err, pgx.ErrNoRows) {
		return errUnknown
	}
	if err != nil {
		return err
	}
	if closed {
		return errClosed
	}
	_, err = tx.Exec(ctx, `INSERT INTO object_gateway.uploads (nonce_hash, key_hash, pending) VALUES ($1,$2,true)`, keyDigest(id), keyDigest(key))
	var pgErr *pgconn.PgError
	if errors.As(err, &pgErr) && pgErr.Code == "23505" {
		return errReplay
	}
	if err != nil {
		return err
	}
	return tx.Commit(ctx)
}

func (l *postgresLedger) finish(ctx context.Context, key, id string) error {
	result, err := l.pool.Exec(ctx, `UPDATE object_gateway.uploads SET pending=false WHERE key_hash=$1 AND nonce_hash=$2 AND pending=true`, keyDigest(key), keyDigest(id))
	if err != nil {
		return err
	}
	if result.RowsAffected() != 1 {
		return errUnknown
	}
	return nil
}

func (l *postgresLedger) close(ctx context.Context, key, registrationID string) (bool, error) {
	tx, err := l.pool.Begin(ctx)
	if err != nil {
		return false, err
	}
	defer tx.Rollback(ctx)
	var closed bool
	err = tx.QueryRow(ctx, `SELECT closed FROM object_gateway.keys WHERE key_hash=$1 AND registration_hash=$2 FOR UPDATE`, keyDigest(key), keyDigest(registrationID)).Scan(&closed)
	if errors.Is(err, pgx.ErrNoRows) {
		return false, errUnknown
	}
	if err != nil {
		return false, err
	}
	if _, err = tx.Exec(ctx, `UPDATE object_gateway.keys SET closed=true WHERE key_hash=$1`, keyDigest(key)); err != nil {
		return false, err
	}
	var pending bool
	if err = tx.QueryRow(ctx, `SELECT EXISTS (SELECT 1 FROM object_gateway.uploads WHERE key_hash=$1 AND pending)`, keyDigest(key)).Scan(&pending); err != nil {
		return false, err
	}
	if err = tx.Commit(ctx); err != nil {
		return false, err
	}
	return !pending, nil
}
func (l *postgresLedger) ping(ctx context.Context) error { return l.pool.Ping(ctx) }

func (l *postgresLedger) status(ctx context.Context, key, id string) (bool, int64, error) {
	var closed bool
	var pending int64
	err := l.pool.QueryRow(ctx, `SELECT k.closed, count(u.nonce_hash) FROM object_gateway.keys k LEFT JOIN object_gateway.uploads u ON u.key_hash=k.key_hash AND u.pending WHERE k.key_hash=$1 AND k.registration_hash=$2 GROUP BY k.closed`, keyDigest(key), keyDigest(id)).Scan(&closed, &pending)
	if errors.Is(err, pgx.ErrNoRows) {
		return false, 0, errUnknown
	}
	return closed, pending, err
}
