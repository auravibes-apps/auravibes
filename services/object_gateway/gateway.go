package main

import (
	"bytes"
	"context"
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"net/url"
	"regexp"
	"strconv"
	"strings"
	"time"
)

type ledger interface {
	register(context.Context, string, string) error
	allow(context.Context, string, string) error
	start(context.Context, string, string, string) error
	finish(context.Context, string, string) error
	close(context.Context, string, string) (bool, error)
	status(context.Context, string, string) (bool, int64, error)
	ping(context.Context) error
}
type storedObject struct {
	body                  io.ReadCloser
	size                  int64
	contentType, checksum string
}
type bucket interface {
	put(context.Context, string, []byte, string, string) error
	get(context.Context, string) (storedObject, error)
	head(context.Context, string) (storedObject, error)
	delete(context.Context, string) error
}

var errNotFound = errors.New("object not found")
var keyPattern = regexp.MustCompile(`^(?:[1-9][0-9]*/)?[a-f0-9]{48}$`)
var checksumPattern = regexp.MustCompile(`^[a-f0-9]{64}$`)

const maxSize = 25 * 1024 * 1024
const readCleanupTimeout = 2 * time.Second

type gateway struct {
	ledger         ledger
	bucket         bucket
	controlToken   string
	signingKey     []byte
	publicBase     *url.URL
	uploadSlots    chan struct{}
	downloadSlots  chan struct{}
	requestTimeout time.Duration
	allowedOrigins map[string]bool
	now            func() time.Time
}
type claims struct {
	Method         string `json:"m"`
	Key            string `json:"k"`
	Expires        int64  `json:"e"`
	ContentType    string `json:"t,omitempty"`
	Length         int64  `json:"l,omitempty"`
	Checksum       string `json:"c,omitempty"`
	Disposition    string `json:"d,omitempty"`
	Nonce          string `json:"n"`
	RegistrationID string `json:"r"`
}

func (g *gateway) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(r.Context(), g.requestTimeout)
	defer cancel()
	r = r.WithContext(ctx)
	w.Header().Set("Cache-Control", "no-store")
	if origin := r.Header.Get("Origin"); origin != "" {
		if !g.allowedOrigins[origin] {
			http.Error(w, "forbidden", 403)
			return
		}
		w.Header().Set("Access-Control-Allow-Origin", origin)
		w.Header().Add("Vary", "Origin")
	}
	if r.Method == http.MethodOptions {
		w.Header().Set("Access-Control-Allow-Methods", "GET, PUT, HEAD, POST, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Authorization, Content-Type, X-Checksum-Sha256, X-Registration-Id")
		w.WriteHeader(204)
		return
	}
	prefix := strings.TrimSuffix(g.publicBase.Path, "/") + "/"
	if !strings.HasPrefix(r.URL.Path, prefix) || r.URL.RawPath != "" {
		http.Error(w, "invalid key", 400)
		return
	}
	key := strings.TrimPrefix(r.URL.Path, prefix)
	if !keyPattern.MatchString(key) {
		http.Error(w, "invalid key", 400)
		return
	}
	if token := r.URL.Query().Get("token"); token != "" {
		g.serveSigned(w, r, key, token)
		return
	}
	if subtle.ConstantTimeCompare([]byte(r.Header.Get("Authorization")), []byte("Bearer "+g.controlToken)) != 1 || g.controlToken == "" {
		http.Error(w, "unauthorized", 401)
		return
	}
	q := r.URL.Query()
	id := r.Header.Get("X-Registration-Id")
	if !checksumPattern.MatchString(id) {
		http.Error(w, "invalid registration", 400)
		return
	}
	switch {
	case r.Method == "GET" && q.Get("status") == "1":
		closed, pending, err := g.ledger.status(r.Context(), key, id)
		if err != nil {
			fail(w, err)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(struct {
			Closed            bool  `json:"closed"`
			PendingOperations int64 `json:"pendingOperations"`
		}{closed, pending})
	case r.Method == "POST" && q.Get("register") == "1":
		if err := g.ledger.register(r.Context(), key, id); err != nil {
			fail(w, err)
			return
		}
		w.WriteHeader(204)
	case r.Method == "POST" && q.Get("quiesce") == "1":
		ready, err := g.ledger.close(r.Context(), key, id)
		if err != nil {
			fail(w, err)
			return
		}
		if !ready {
			http.Error(w, "pending", 409)
			return
		}
		w.WriteHeader(204)
	case r.Method == "POST" && q.Get("sign") != "":
		g.sign(w, r, key, id)
	case r.Method == "HEAD":
		idBytes := make([]byte, 24)
		if _, err := rand.Read(idBytes); err != nil {
			http.Error(w, "unavailable", 503)
			return
		}
		reservation := hex.EncodeToString(idBytes)
		if err := g.ledger.start(r.Context(), key, id, reservation); err != nil {
			fail(w, err)
			return
		}
		obj, err := g.bucket.head(r.Context(), key)
		if err != nil {
			g.finishRead(r.Context(), key, reservation)
			fail(w, err)
			return
		}
		w.Header().Set("Content-Length", strconv.FormatInt(obj.size, 10))
		w.Header().Set("Content-Type", obj.contentType)
		w.Header().Set("X-Checksum-Sha256", obj.checksum)
		w.WriteHeader(200)
		_ = http.NewResponseController(w).Flush()
		g.finishRead(r.Context(), key, reservation)

	case r.Method == "DELETE":
		ready, err := g.ledger.close(r.Context(), key, id)
		if err != nil {
			fail(w, err)
			return
		}
		if !ready {
			http.Error(w, "pending", 409)
			return
		}
		if err = g.bucket.delete(r.Context(), key); err != nil {
			if errors.Is(err, errReplicaProvenanceUnavailable) {
				w.Header().Set("Content-Type", "application/json")
				w.WriteHeader(http.StatusUnprocessableEntity)
				_, _ = io.WriteString(w, `{"code":"replica_provenance_unavailable"}`)
				return
			}
			http.Error(w, "storage unavailable", 502)
			return
		}
		w.WriteHeader(204)
	default:
		http.Error(w, "unsupported", 405)
	}
}
func fail(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, errClosed):
		http.Error(w, "closed", 403)
	case errors.Is(err, errUnknown), errors.Is(err, errReplay):
		http.Error(w, "conflict", 409)
	case errors.Is(err, errNotFound):
		http.Error(w, "not found", 404)
	default:
		http.Error(w, "unavailable", 503)
	}
}
func (g *gateway) sign(w http.ResponseWriter, r *http.Request, key, id string) {
	if err := g.ledger.allow(r.Context(), key, id); err != nil {
		fail(w, err)
		return
	}
	q := r.URL.Query()
	expires, err := strconv.ParseInt(q.Get("expires"), 10, 64)
	now := g.now().Unix()
	if err != nil || expires <= now || expires > now+600 {
		http.Error(w, "invalid expiry", 400)
		return
	}
	c := claims{Method: q.Get("sign"), Key: key, Expires: expires, RegistrationID: id}
	if c.Method == "PUT" {
		c.ContentType = q.Get("content-type")
		c.Length, err = strconv.ParseInt(q.Get("content-length"), 10, 64)
		c.Checksum = q.Get("x-checksum-sha256")
		if err != nil || c.Length < 1 || c.Length > maxSize || c.ContentType == "" || strings.ContainsAny(c.ContentType, "\r\n") || !checksumPattern.MatchString(c.Checksum) {
			http.Error(w, "invalid upload", 400)
			return
		}
	} else if c.Method == "GET" {
		c.Disposition = q.Get("response-content-disposition")
		if strings.ContainsAny(c.Disposition, "\r\n") || q.Get("response-cache-control") != "no-store" {
			http.Error(w, "invalid download", 400)
			return
		}
	} else {
		http.Error(w, "invalid method", 400)
		return
	}
	nonce := make([]byte, 24)
	if _, err = rand.Read(nonce); err != nil {
		http.Error(w, "unavailable", 503)
		return
	}
	c.Nonce = hex.EncodeToString(nonce)
	data, err := json.Marshal(c)
	if err != nil {
		http.Error(w, "unavailable", 503)
		return
	}
	raw := base64.RawURLEncoding.EncodeToString(data)
	mac := hmac.New(sha256.New, g.signingKey)
	mac.Write([]byte(raw))
	token := raw + "." + base64.RawURLEncoding.EncodeToString(mac.Sum(nil))
	target := *g.publicBase
	target.Path = strings.TrimSuffix(target.Path, "/") + "/" + key
	target.RawQuery = url.Values{"token": {token}}.Encode()
	_, _ = io.WriteString(w, target.String())
}
func (g *gateway) serveSigned(w http.ResponseWriter, r *http.Request, key, token string) {
	parts := strings.Split(token, ".")
	if len(parts) != 2 {
		http.Error(w, "invalid token", 403)
		return
	}
	mac := hmac.New(sha256.New, g.signingKey)
	mac.Write([]byte(parts[0]))
	sig, err := base64.RawURLEncoding.DecodeString(parts[1])
	if err != nil || !hmac.Equal(sig, mac.Sum(nil)) {
		http.Error(w, "invalid token", 403)
		return
	}
	data, err := base64.RawURLEncoding.DecodeString(parts[0])
	var c claims
	if err != nil || json.Unmarshal(data, &c) != nil || c.Key != key || c.Method != r.Method || c.Expires <= g.now().Unix() {
		http.Error(w, "invalid token", 403)
		return
	}
	if err = g.ledger.allow(r.Context(), key, c.RegistrationID); err != nil {
		fail(w, err)
		return
	}
	if r.Method == "GET" {
		select {
		case g.downloadSlots <- struct{}{}:
			defer func() { <-g.downloadSlots }()
		default:
			http.Error(w, "busy", 503)
			return
		}
		readID := make([]byte, 24)
		if _, err = rand.Read(readID); err != nil {
			http.Error(w, "unavailable", 503)
			return
		}
		reservation := hex.EncodeToString(readID)
		if err = g.ledger.start(r.Context(), key, c.RegistrationID, reservation); err != nil {
			fail(w, err)
			return
		}
		obj, err := g.bucket.get(r.Context(), key)
		if err != nil {
			g.finishRead(r.Context(), key, reservation)
			fail(w, err)
			return
		}
		w.Header().Set("Content-Type", obj.contentType)
		w.Header().Set("Content-Length", strconv.FormatInt(obj.size, 10))
		w.Header().Set("Content-Disposition", c.Disposition)
		written, copyErr := io.Copy(w, obj.body)
		closeErr := obj.body.Close()
		if closeErr != nil {
			return
		}
		if copyErr == nil && written == obj.size {
			_ = http.NewResponseController(w).Flush()
		}
		// The read and all gateway writes have ended. External buffered bytes
		// may still be delivered, but no further stream operation can start.
		g.finishRead(r.Context(), key, reservation)
		return
	}
	select {
	case g.uploadSlots <- struct{}{}:
		defer func() { <-g.uploadSlots }()
	default:
		http.Error(w, "busy", 503)
		return
	}
	if r.ContentLength != c.Length || r.Header.Get("Content-Type") != c.ContentType || r.Header.Get("X-Checksum-Sha256") != c.Checksum {
		http.Error(w, "invalid upload", 400)
		return
	}
	body, err := io.ReadAll(io.LimitReader(r.Body, c.Length+1))
	sum := sha256.Sum256(body)
	if err != nil || int64(len(body)) != c.Length || !bytes.Equal([]byte(hex.EncodeToString(sum[:])), []byte(c.Checksum)) || c.Expires <= g.now().Unix() {
		http.Error(w, "invalid upload", 400)
		return
	}
	if err = g.ledger.start(r.Context(), key, c.RegistrationID, c.Nonce); err != nil {
		fail(w, err)
		return
	}
	if err = g.bucket.put(r.Context(), key, body, c.ContentType, c.Checksum); err != nil {
		http.Error(w, "storage unavailable", 502)
		return
	}
	if err = g.ledger.finish(r.Context(), key, c.Nonce); err != nil {
		http.Error(w, "unavailable", 503)
		return
	}
	w.WriteHeader(204)
}

// The request may be canceled after a pre-stream failure or a successful flush.
// Use a bounded independent context; a failed finish remains safely pending.
func (g *gateway) finishRead(ctx context.Context, key, reservation string) {
	cleanup, cancel := context.WithTimeout(context.WithoutCancel(ctx), readCleanupTimeout)
	defer cancel()
	_ = g.ledger.finish(cleanup, key, reservation)
}
