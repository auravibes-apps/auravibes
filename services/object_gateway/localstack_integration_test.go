package main

import (
	"bytes"
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Both endpoints must be disposable local containers; no real provider is used.
func TestLocalStackGatewayLifecycle(t *testing.T) {
	endpoint, database := os.Getenv("GATEWAY_LOCALSTACK_ENDPOINT"), os.Getenv("GATEWAY_TEST_DATABASE_URL")
	if endpoint == "" || database == "" {
		t.Skip("set GATEWAY_LOCALSTACK_ENDPOINT and GATEWAY_TEST_DATABASE_URL for disposable local containers")
	}
	u, err := url.Parse(endpoint)
	if err != nil || u.Scheme != "http" || !loopbackHost(u.Hostname()) || u.User != nil || u.Path != "" || u.RawQuery != "" || u.Fragment != "" {
		t.Fatal("LocalStack endpoint must be a loopback HTTP origin")
	}
	dbConfig, err := pgxpool.ParseConfig(database)
	if err != nil || !loopbackHost(dbConfig.ConnConfig.Host) || dbConfig.ConnConfig.Database != "gateway_1691_test" {
		t.Fatal("database must be the disposable loopback gateway_1691_test database")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()
	pool, err := pgxpool.NewWithConfig(ctx, dbConfig)
	if err != nil {
		t.Fatal("cannot open disposable database")
	}
	t.Cleanup(pool.Close)
	schema, err := os.ReadFile("schema.sql")
	if err != nil {
		t.Fatal("cannot read gateway schema")
	}
	if _, err := pool.Exec(ctx, string(schema)); err != nil {
		t.Fatal("disposable database must be empty")
	}
	cfg, err := config.LoadDefaultConfig(ctx, config.WithRegion("us-east-1"), config.WithCredentialsProvider(credentials.NewStaticCredentialsProvider("test", "test", "")))
	if err != nil {
		t.Fatal("cannot configure synthetic credentials")
	}
	client := s3.NewFromConfig(cfg, func(o *s3.Options) {
		o.BaseEndpoint = aws.String(endpoint)
		o.UsePathStyle = true
	})
	var suffix [12]byte
	if _, err := rand.Read(suffix[:]); err != nil {
		t.Fatal("cannot generate synthetic bucket name")
	}
	bucketName := "auravibes-1691-synthetic-" + hex.EncodeToString(suffix[:])
	if _, err := client.CreateBucket(ctx, &s3.CreateBucketInput{Bucket: aws.String(bucketName)}); err != nil {
		t.Fatal("cannot create synthetic bucket")
	}
	t.Cleanup(func() {
		cleanup, stop := context.WithTimeout(context.Background(), 10*time.Second)
		defer stop()
		if _, err := client.DeleteBucket(cleanup, &s3.DeleteBucketInput{Bucket: aws.String(bucketName)}); err != nil {
			t.Error("synthetic bucket cleanup failed")
		}
	})
	t.Cleanup(func() {
		cleanup, stop := context.WithTimeout(context.Background(), 10*time.Second)
		defer stop()
		for _, key := range []string{testKey, localstackUncertainKey} {
			if _, err := client.DeleteObject(cleanup, &s3.DeleteObjectInput{Bucket: aws.String(bucketName), Key: aws.String(key)}); err != nil {
				t.Error("synthetic object cleanup failed")
			}
		}
	})
	g := &gateway{
		ledger: &postgresLedger{pool: pool}, bucket: &s3Bucket{client: client, name: bucketName},
		controlToken: "test-control-token-with-sufficient-length", signingKey: []byte(strings.Repeat("k", 32)),
		publicBase: mustURL("https://gateway.example/objects"), uploadSlots: make(chan struct{}, 2),
		downloadSlots: make(chan struct{}, 2), requestTimeout: 10 * time.Second, now: time.Now,
	}
	base := "https://gateway.example/objects/" + testKey
	if result := control(g, "POST", base+"?register=1"); result.Code != http.StatusNoContent {
		t.Fatalf("register returned %d", result.Code)
	}
	body := []byte("synthetic gateway lifecycle")
	if os.Getenv("GATEWAY_RUN_CAPACITY_BENCHMARK") == "1" {
		body = bytes.Repeat([]byte("A"), 25*1024*1024)
	}
	putURL := signPut(t, g, body)
	uploadStart := time.Now()
	if result := signedPut(g, putURL, body); result.Code != http.StatusNoContent {
		t.Fatalf("upload returned %d", result.Code)
	}
	uploadElapsed := time.Since(uploadStart)
	query := url.Values{"sign": {"GET"}, "expires": {strconv.FormatInt(time.Now().Add(time.Minute).Unix(), 10)}, "response-content-disposition": {"attachment"}, "response-cache-control": {"no-store"}}
	signed := control(g, "POST", base+"?"+query.Encode())
	if signed.Code != http.StatusOK {
		t.Fatalf("sign download returned %d", signed.Code)
	}
	read := httptest.NewRecorder()
	readStart := time.Now()
	g.ServeHTTP(read, httptest.NewRequest("GET", signed.Body.String(), nil))
	readElapsed := time.Since(readStart)
	if read.Code != http.StatusOK || !bytes.Equal(read.Body.Bytes(), body) {
		t.Fatal("gateway download did not return the synthetic content")
	}
	if os.Getenv("GATEWAY_RUN_CAPACITY_BENCHMARK") == "1" {
		t.Logf("synthetic gateway asset: bytes=%d upload_us=%d read_us=%d storage=localstack ledger=postgres transport=inprocess", len(body), uploadElapsed.Microseconds(), readElapsed.Microseconds())
	}
	if result := control(g, "POST", base+"?quiesce=1"); result.Code != http.StatusNoContent {
		t.Fatalf("quiescence returned %d", result.Code)
	}
	if result := signedPut(g, putURL, body); result.Code != http.StatusForbidden {
		t.Fatalf("closed key accepted upload: %d", result.Code)
	}
	if result := control(g, "DELETE", base); result.Code != http.StatusUnprocessableEntity || !strings.Contains(result.Body.String(), "replica_provenance_unavailable") {
		t.Fatal("gateway did not block deletion without provider provenance")
	}
	if _, err := client.HeadObject(ctx, &s3.HeadObjectInput{Bucket: aws.String(bucketName), Key: aws.String(testKey)}); err != nil {
		t.Fatal("blocked deletion removed the synthetic object")
	}

	uncertain := *g
	uncertain.bucket = uncertainLocalStackBucket{bucket: &s3Bucket{client: client, name: bucketName}}
	uncertainBase := "https://gateway.example/objects/" + localstackUncertainKey
	if result := control(&uncertain, "POST", uncertainBase+"?register=1"); result.Code != http.StatusNoContent {
		t.Fatalf("uncertain-key registration returned %d", result.Code)
	}
	sum := sha256.Sum256(body)
	putQuery := url.Values{"sign": {"PUT"}, "expires": {strconv.FormatInt(time.Now().Add(time.Minute).Unix(), 10)}, "content-type": {"text/plain"}, "content-length": {strconv.Itoa(len(body))}, "x-checksum-sha256": {hex.EncodeToString(sum[:])}}
	uncertainSigned := control(&uncertain, "POST", uncertainBase+"?"+putQuery.Encode())
	if uncertainSigned.Code != http.StatusOK {
		t.Fatalf("uncertain-key signing returned %d", uncertainSigned.Code)
	}
	if result := signedPut(&uncertain, uncertainSigned.Body.String(), body); result.Code != http.StatusBadGateway {
		t.Fatalf("uncertain upload returned %d", result.Code)
	}
	if _, err := client.HeadObject(ctx, &s3.HeadObjectInput{Bucket: aws.String(bucketName), Key: aws.String(localstackUncertainKey)}); err != nil {
		t.Fatal("synthetic uncertain write was not stored")
	}
	restarted := uncertain
	restarted.ledger = &postgresLedger{pool: pool}
	status := control(&restarted, "GET", uncertainBase+"?status=1")
	if status.Code != http.StatusOK || status.Body.String() != "{\"closed\":false,\"pendingOperations\":1}\n" {
		t.Fatal("pending reservation did not survive gateway restart")
	}
	if result := control(&restarted, "POST", uncertainBase+"?quiesce=1"); result.Code != http.StatusConflict {
		t.Fatalf("quiescence accepted uncertain upload: %d", result.Code)
	}
	if result := control(&restarted, "DELETE", uncertainBase); result.Code != http.StatusConflict {
		t.Fatalf("deletion accepted uncertain upload: %d", result.Code)
	}
	status = control(&restarted, "GET", uncertainBase+"?status=1")
	if status.Code != http.StatusOK || status.Body.String() != "{\"closed\":true,\"pendingOperations\":1}\n" {
		t.Fatal("uncertain reservation was cleared or key remained open")
	}
	if _, err := client.HeadObject(ctx, &s3.HeadObjectInput{Bucket: aws.String(bucketName), Key: aws.String(localstackUncertainKey)}); err != nil {
		t.Fatal("blocked deletion removed the uncertain object")
	}
}

func loopbackHost(host string) bool { return host == "127.0.0.1" || host == "::1" }

const localstackUncertainKey = "2/bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"

type uncertainLocalStackBucket struct{ bucket }

func (b uncertainLocalStackBucket) put(ctx context.Context, key string, data []byte, contentType, checksum string) error {
	if err := b.bucket.put(ctx, key, data, contentType, checksum); err != nil {
		return err
	}
	return errors.New("synthetic uncertain provider outcome")
}
