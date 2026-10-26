package main

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"io"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strconv"
	"strings"
	"sync"
	"testing"
	"time"
)

const testKey = "1/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

type fakeLedger struct {
	mu         sync.Mutex
	closed     map[string]bool
	pending    map[string]map[string]bool
	seen       map[string]bool
	registered map[string]string
}

func newFakeLedger() *fakeLedger {
	return &fakeLedger{closed: map[string]bool{}, pending: map[string]map[string]bool{}, seen: map[string]bool{}, registered: map[string]string{testKey: strings.Repeat("a", 64)}}
}
func (l *fakeLedger) register(_ context.Context, key, id string) error {
	l.mu.Lock()
	defer l.mu.Unlock()
	old, ok := l.registered[key]
	if ok && old != id {
		return errReplay
	}
	l.registered[key] = id
	return nil
}

func (l *fakeLedger) allow(_ context.Context, key, id string) error {
	l.mu.Lock()
	defer l.mu.Unlock()
	if l.registered[key] != id {
		return errUnknown
	}
	if l.closed[key] {
		return errClosed
	}
	return nil
}
func (l *fakeLedger) start(_ context.Context, key, registrationID, id string) error {
	l.mu.Lock()
	defer l.mu.Unlock()
	if l.registered[key] != registrationID {
		return errUnknown
	}
	if l.closed[key] {
		return errClosed
	}
	if l.seen[id] {
		return errReplay
	}
	l.seen[id] = true
	if l.pending[key] == nil {
		l.pending[key] = map[string]bool{}
	}
	l.pending[key][id] = true
	return nil
}
func (l *fakeLedger) finish(_ context.Context, key, id string) error {
	l.mu.Lock()
	defer l.mu.Unlock()
	delete(l.pending[key], id)
	return nil
}
func (l *fakeLedger) close(_ context.Context, key, registrationID string) (bool, error) {
	l.mu.Lock()
	defer l.mu.Unlock()
	if l.registered[key] != registrationID {
		return false, errUnknown
	}
	l.closed[key] = true
	return len(l.pending[key]) == 0, nil
}
func (l *fakeLedger) ping(context.Context) error { return nil }

type fakeBucket struct {
	mu      sync.Mutex
	objects map[string]storedObject
	started chan struct{}
	release chan struct{}
	fail    bool
	writes  int
}

func newFakeBucket() *fakeBucket { return &fakeBucket{objects: map[string]storedObject{}} }
func (b *fakeBucket) put(_ context.Context, key string, data []byte, contentType, checksum string) error {
	if b.started != nil {
		close(b.started)
		<-b.release
	}
	b.mu.Lock()
	defer b.mu.Unlock()
	b.writes++
	if b.fail {
		return errors.New("private upstream error")
	}
	b.objects[key] = storedObject{body: io.NopCloser(bytes.NewReader(bytes.Clone(data))), size: int64(len(data)), contentType: contentType, checksum: checksum}
	return nil
}
func (b *fakeBucket) get(_ context.Context, key string) (storedObject, error) {
	b.mu.Lock()
	defer b.mu.Unlock()
	obj, ok := b.objects[key]
	if !ok {
		return storedObject{}, errNotFound
	}
	data, _ := io.ReadAll(obj.body)
	obj.body = io.NopCloser(bytes.NewReader(data))
	b.objects[key] = storedObject{body: io.NopCloser(bytes.NewReader(data)), size: obj.size, contentType: obj.contentType, checksum: obj.checksum}
	return obj, nil
}
func (b *fakeBucket) head(ctx context.Context, key string) (storedObject, error) {
	obj, err := b.get(ctx, key)
	if err == nil {
		_ = obj.body.Close()
	}
	return obj, err
}
func (b *fakeBucket) delete(_ context.Context, key string) error {
	b.mu.Lock()
	defer b.mu.Unlock()
	delete(b.objects, key)
	return nil
}

func testGateway(l *fakeLedger, b *fakeBucket) *gateway {
	return &gateway{ledger: l, bucket: b, controlToken: "test-control-token-with-sufficient-length", signingKey: []byte(strings.Repeat("k", 32)), publicBase: mustURL("https://gateway.example/objects"), uploadSlots: make(chan struct{}, 2), allowedOrigins: map[string]bool{"https://app.example": true}, now: time.Now}
}
func mustURL(s string) *url.URL {
	u, err := url.Parse(s)
	if err != nil {
		panic(err)
	}
	return u
}
func control(g *gateway, method, target string) *httptest.ResponseRecorder {
	req := httptest.NewRequest(method, target, nil)
	req.Header.Set("Authorization", "Bearer test-control-token-with-sufficient-length")
	req.Header.Set("X-Registration-Id", strings.Repeat("a", 64))
	w := httptest.NewRecorder()
	g.ServeHTTP(w, req)
	return w
}
func signPut(t *testing.T, g *gateway, body []byte) string {
	t.Helper()
	sum := sha256.Sum256(body)
	q := url.Values{"sign": {"PUT"}, "expires": {strconv.FormatInt(time.Now().Add(5*time.Minute).Unix(), 10)}, "content-type": {"text/plain"}, "content-length": {strconv.Itoa(len(body))}, "x-checksum-sha256": {hex.EncodeToString(sum[:])}}
	w := control(g, "POST", "https://gateway.example/objects/"+testKey+"?"+q.Encode())
	if w.Code != http.StatusOK {
		t.Fatalf("sign: %d %s", w.Code, w.Body.String())
	}
	return w.Body.String()
}
func signedPut(g *gateway, target string, body []byte) *httptest.ResponseRecorder {
	sum := sha256.Sum256(body)
	req := httptest.NewRequest("PUT", target, bytes.NewReader(body))
	req.Header.Set("Content-Type", "text/plain")
	req.Header.Set("X-Checksum-Sha256", hex.EncodeToString(sum[:]))
	w := httptest.NewRecorder()
	g.ServeHTTP(w, req)
	return w
}

func TestQuiescenceClosesPreviouslySignedURLs(t *testing.T) {
	l, b := newFakeLedger(), newFakeBucket()
	g := testGateway(l, b)
	body := []byte("data")
	putURL := signPut(t, g, body)
	if got := signedPut(g, putURL, body).Code; got != http.StatusNoContent {
		t.Fatalf("put status %d", got)
	}
	q := url.Values{"sign": {"GET"}, "expires": {strconv.FormatInt(time.Now().Add(time.Minute).Unix(), 10)}, "response-content-disposition": {"attachment"}, "response-cache-control": {"no-store"}}
	signed := control(g, "POST", "https://gateway.example/objects/"+testKey+"?"+q.Encode())
	if signed.Code != 200 {
		t.Fatal(signed.Code)
	}
	before := httptest.NewRecorder()
	g.ServeHTTP(before, httptest.NewRequest("GET", signed.Body.String(), nil))
	if before.Code != 200 || before.Body.String() != "data" {
		t.Fatal("download failed")
	}
	if got := control(g, "POST", "https://gateway.example/objects/"+testKey+"?quiesce=1").Code; got != 204 {
		t.Fatalf("quiesce %d", got)
	}
	if got := signedPut(g, putURL, body).Code; got != http.StatusForbidden {
		t.Fatalf("closed put %d", got)
	}
	after := httptest.NewRecorder()
	g.ServeHTTP(after, httptest.NewRequest("GET", signed.Body.String(), nil))
	if after.Code != http.StatusForbidden {
		t.Fatalf("closed get %d", after.Code)
	}
	if got := control(g, "DELETE", "https://gateway.example/objects/"+testKey).Code; got != 204 {
		t.Fatalf("delete %d", got)
	}
}

func TestQuiescenceWaitsForDurableUpload(t *testing.T) {
	l, b := newFakeLedger(), newFakeBucket()
	b.started = make(chan struct{})
	b.release = make(chan struct{})
	g := testGateway(l, b)
	body := []byte("data")
	target := signPut(t, g, body)
	result := make(chan int, 1)
	go func() { result <- signedPut(g, target, body).Code }()
	select {
	case <-b.started:
	case <-time.After(5 * time.Second):
		t.Fatal("upload not dispatched")
	}
	if got := control(g, "POST", "https://gateway.example/objects/"+testKey+"?quiesce=1").Code; got != http.StatusConflict {
		t.Fatalf("inflight quiescence %d", got)
	}
	close(b.release)
	if got := <-result; got != 204 {
		t.Fatalf("put %d", got)
	}
	if got := control(g, "POST", "https://gateway.example/objects/"+testKey+"?quiesce=1").Code; got != 204 {
		t.Fatalf("completed quiescence %d", got)
	}
}

func TestUncertainWriteRemainsBlockedAfterRestart(t *testing.T) {
	l, b := newFakeLedger(), newFakeBucket()
	b.fail = true
	g := testGateway(l, b)
	target := signPut(t, g, []byte("data"))
	w := signedPut(g, target, []byte("data"))
	if w.Code != 502 || strings.Contains(w.Body.String(), "private upstream error") {
		t.Fatal("unsafe upstream failure")
	}
	restarted := testGateway(l, b)
	if got := control(restarted, "POST", "https://gateway.example/objects/"+testKey+"?quiesce=1").Code; got != 409 {
		t.Fatalf("unknown upload unblocked: %d", got)
	}
	if got := control(restarted, "DELETE", "https://gateway.example/objects/"+testKey).Code; got != 409 {
		t.Fatalf("unknown upload deleted: %d", got)
	}
}

func TestInvalidCredentialsPathAndPayloadAreRejected(t *testing.T) {
	l, b := newFakeLedger(), newFakeBucket()
	g := testGateway(l, b)
	w := httptest.NewRecorder()
	g.ServeHTTP(w, httptest.NewRequest("POST", "https://gateway.example/objects/"+testKey+"?quiesce=1", nil))
	if w.Code != 401 {
		t.Fatal(w.Code)
	}
	if got := control(g, "POST", "https://gateway.example/objects/../escape?quiesce=1").Code; got != 400 {
		t.Fatalf("unsafe path %d", got)
	}
	target := signPut(t, g, []byte("data"))
	if got := signedPut(g, target, []byte("evil")).Code; got != 400 {
		t.Fatalf("checksum mismatch %d", got)
	}
	if b.writes != 0 {
		t.Fatal("invalid payload reached storage")
	}
	if got := control(g, "POST", "https://gateway.example/objects/"+testKey+"?quiesce=1").Code; got != 204 {
		t.Fatal(got)
	}
}

func TestUnknownKeyCannotBeAttested(t *testing.T) {
	l, b := newFakeLedger(), newFakeBucket()
	g := testGateway(l, b)
	unknown := "2/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
	if got := control(g, "POST", "https://gateway.example/objects/"+unknown+"?quiesce=1").Code; got != 409 {
		t.Fatalf("unknown key quiesce: %d", got)
	}
	if got := control(g, "DELETE", "https://gateway.example/objects/"+unknown).Code; got != 409 {
		t.Fatalf("unknown key delete: %d", got)
	}
}

func TestRegistrationIsIdempotentButCannotChangeProvenance(t *testing.T) {
	g := testGateway(newFakeLedger(), newFakeBucket())
	key := "2/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
	register := func(id string) int {
		req := httptest.NewRequest("POST", "https://gateway.example/objects/"+key+"?register=1", nil)
		req.Header.Set("Authorization", "Bearer test-control-token-with-sufficient-length")
		req.Header.Set("X-Registration-Id", id)
		w := httptest.NewRecorder()
		g.ServeHTTP(w, req)
		return w.Code
	}
	id := strings.Repeat("a", 64)
	if got := register(id); got != 204 {
		t.Fatal(got)
	}
	if got := register(id); got != 204 {
		t.Fatal(got)
	}
	if got := register(strings.Repeat("b", 64)); got != 409 {
		t.Fatal(got)
	}
}

func TestMismatchedRegistrationCannotSignOrAttest(t *testing.T) {
	g := testGateway(newFakeLedger(), newFakeBucket())
	call := func(method, query, id string) int {
		req := httptest.NewRequest(method, "https://gateway.example/objects/"+testKey+query, nil)
		req.Header.Set("Authorization", "Bearer test-control-token-with-sufficient-length")
		req.Header.Set("X-Registration-Id", id)
		w := httptest.NewRecorder()
		g.ServeHTTP(w, req)
		return w.Code
	}
	wrong := strings.Repeat("b", 64)
	if got := call("POST", "?quiesce=1", wrong); got != 409 {
		t.Fatal(got)
	}
	if got := call("DELETE", "", wrong); got != 409 {
		t.Fatal(got)
	}
	if got := call("POST", "?quiesce=1", strings.Repeat("a", 64)); got != 204 {
		t.Fatal(got)
	}
	if got := call("POST", "?register=1", strings.Repeat("a", 64)); got != 204 {
		t.Fatal(got)
	}
	if got := call("POST", "?sign=GET", strings.Repeat("a", 64)); got != 403 {
		t.Fatal(got)
	}
}
