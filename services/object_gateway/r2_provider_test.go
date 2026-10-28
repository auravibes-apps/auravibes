package main

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"io"
	"net/url"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

// This test is restricted to explicitly named disposable issue 1691 buckets.
func TestDisposableR2Provider(t *testing.T) {
	if os.Getenv("R2_TEST_LIVE") != "1" {
		t.Skip("set R2_TEST_LIVE=1 for the disposable R2 provider test")
	}
	bucketName, endpoint := os.Getenv("R2_TEST_BUCKET"), os.Getenv("R2_TEST_ENDPOINT")
	u, err := url.Parse(endpoint)
	if !strings.HasPrefix(bucketName, "auravibes-1691-test-") || err != nil || u.Scheme != "https" || !strings.HasSuffix(u.Hostname(), ".r2.cloudflarestorage.com") || u.User != nil || u.Path != "" || u.RawQuery != "" || u.Fragment != "" {
		t.Fatal("a disposable 1691 bucket and Cloudflare R2 endpoint are required")
	}
	if os.Getenv("R2_TEST_DRY_RUN") == "1" {
		t.Log("dry run: write, read, verify gateway deletion remains blocked, then delete one synthetic object in the disposable bucket")
		return
	}
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()
	cfg, err := config.LoadDefaultConfig(ctx, config.WithRegion("auto"))
	if err != nil {
		t.Fatal("R2 credentials unavailable")
	}
	client := s3.NewFromConfig(cfg, func(o *s3.Options) {
		o.BaseEndpoint = aws.String(endpoint)
		o.UsePathStyle = true
	})
	key := "1691-test/" + time.Now().UTC().Format("20060102T150405.000000000")
	cleanup := func() error {
		_, err := client.DeleteObject(context.Background(), &s3.DeleteObjectInput{Bucket: aws.String(bucketName), Key: aws.String(key)})
		return err
	}
	t.Cleanup(func() {
		if err := cleanup(); err != nil {
			t.Error("synthetic R2 object cleanup failed")
		}
	})
	body := []byte("synthetic workspace erasure test")
	sum := sha256.Sum256(body)
	bucket := &s3Bucket{client: client, name: bucketName}
	if err := bucket.put(ctx, key, body, "text/plain", hex.EncodeToString(sum[:])); err != nil {
		t.Fatal("synthetic R2 upload failed")
	}
	object, err := bucket.get(ctx, key)
	if err != nil {
		t.Fatal("synthetic R2 read failed")
	}
	read, err := io.ReadAll(object.body)
	_ = object.body.Close()
	if err != nil || string(read) != string(body) || object.checksum != hex.EncodeToString(sum[:]) {
		t.Fatal("synthetic R2 content or checksum mismatch")
	}
	if err := bucket.delete(ctx, key); err != errReplicaProvenanceUnavailable {
		t.Fatal("gateway did not block deletion without provider provenance")
	}
	if err := cleanup(); err != nil {
		t.Fatal("synthetic R2 deletion failed")
	}
	if _, err := bucket.head(ctx, key); err != errNotFound {
		t.Fatal("synthetic R2 object was not confirmed absent")
	}
}
