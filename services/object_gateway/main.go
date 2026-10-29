package main

import (
	"context"
	"errors"
	"log"
	"net/http"
	"net/url"
	"os"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/jackc/pgx/v5/pgxpool"
)

func run(ctx context.Context) error {
	control, secret := os.Getenv("GATEWAY_CONTROL_TOKEN"), os.Getenv("GATEWAY_SIGNING_KEY")
	if len(control) < 32 || len(secret) < 32 {
		return errors.New("control token and signing key must each contain at least 32 bytes")
	}
	base, err := url.Parse(os.Getenv("GATEWAY_PUBLIC_BASE_URL"))
	if err != nil || base.Scheme != "https" || base.Host == "" || base.User != nil || base.RawQuery != "" || base.Fragment != "" {
		return errors.New("invalid public base URL")
	}
	capacity, err := strconv.Atoi(os.Getenv("GATEWAY_MAX_CONCURRENT_UPLOADS"))
	if err != nil || capacity < 1 {
		return errors.New("invalid upload capacity")
	}
	downloadCapacity, err := strconv.Atoi(os.Getenv("GATEWAY_MAX_CONCURRENT_DOWNLOADS"))
	if err != nil || downloadCapacity < 1 {
		return errors.New("invalid download capacity")
	}
	requestTimeoutSeconds, err := strconv.Atoi(os.Getenv("GATEWAY_REQUEST_TIMEOUT_SECONDS"))
	if err != nil || requestTimeoutSeconds < 1 || requestTimeoutSeconds > 3600 {
		return errors.New("invalid request timeout")
	}
	readTimeoutSeconds, err := strconv.Atoi(os.Getenv("GATEWAY_READ_TIMEOUT_SECONDS"))
	if err != nil || readTimeoutSeconds < 1 || readTimeoutSeconds > 3600 {
		return errors.New("invalid request read timeout")
	}
	db, bucketName, region := os.Getenv("GATEWAY_DATABASE_URL"), os.Getenv("S3_BUCKET"), os.Getenv("AWS_REGION")
	if db == "" || bucketName == "" || region == "" {
		return errors.New("database, bucket, and region are required")
	}
	origins := map[string]bool{}
	for _, value := range strings.Split(os.Getenv("GATEWAY_ALLOWED_ORIGINS"), ",") {
		if value == "" {
			continue
		}
		u, e := url.Parse(value)
		if e != nil || u.Scheme != "https" || u.Host == "" || u.User != nil || u.Path != "" || u.RawQuery != "" || u.Fragment != "" {
			return errors.New("invalid allowed origin")
		}
		origins[value] = true
	}
	pool, err := pgxpool.New(ctx, db)
	if err != nil {
		return errors.New("database configuration failed")
	}
	defer pool.Close()
	l := &postgresLedger{pool: pool}
	if err = l.ping(ctx); err != nil {
		return errors.New("database unavailable")
	}
	var exists bool
	if err = pool.QueryRow(ctx, `SELECT to_regclass('object_gateway.keys') IS NOT NULL AND to_regclass('object_gateway.uploads') IS NOT NULL`).Scan(&exists); err != nil || !exists {
		return errors.New("gateway schema unavailable")
	}
	cfg, err := config.LoadDefaultConfig(ctx, config.WithRegion(region))
	if err != nil {
		return errors.New("storage configuration failed")
	}
	endpoint := os.Getenv("S3_ENDPOINT")
	if endpoint != "" {
		u, e := url.Parse(endpoint)
		if e != nil || u.Scheme != "https" || u.Host == "" || u.User != nil {
			return errors.New("invalid storage endpoint")
		}
	}
	erasureMode := os.Getenv("GATEWAY_ERASURE_PROVIDER")
	if erasureMode != "" && (erasureMode != "aws-s3" || endpoint != "" || !regexp.MustCompile(`^[a-z]{2}(-[a-z]+)+-[0-9]+$`).MatchString(region)) {
		return errors.New("unsupported erasure provider")
	}
	client := s3.NewFromConfig(cfg, func(o *s3.Options) {
		if erasureMode == "aws-s3" {
			o.BaseEndpoint = aws.String("https://s3." + region + ".amazonaws.com")
		}
		if endpoint != "" {
			o.BaseEndpoint = aws.String(endpoint)
			o.UsePathStyle = true
		}
	})
	g := &gateway{ledger: l, bucket: &s3Bucket{client: client, name: bucketName, allowAWSErasure: erasureMode == "aws-s3"}, controlToken: control, signingKey: []byte(secret), publicBase: base, uploadSlots: make(chan struct{}, capacity), downloadSlots: make(chan struct{}, downloadCapacity), requestTimeout: time.Duration(requestTimeoutSeconds) * time.Second, allowedOrigins: origins, now: time.Now}
	addr := os.Getenv("GATEWAY_LISTEN_ADDR")
	if addr == "" {
		addr = ":8080"
	}
	server := newServer(addr, g, time.Duration(readTimeoutSeconds)*time.Second, time.Duration(requestTimeoutSeconds)*time.Second)
	return server.ListenAndServe()
}
func main() {
	if len(os.Args) == 2 && os.Args[1] == "audit-bucket" {
		os.Exit(runBucketAudit(context.Background()))
	}
	if len(os.Args) != 1 {
		log.Print("unsupported command")
		os.Exit(2)
	}
	if err := run(context.Background()); err != nil {
		log.Print("gateway stopped: ", err)
		os.Exit(1)
	}
}

func newServer(addr string, handler http.Handler, readTimeout, writeTimeout time.Duration) *http.Server {
	return &http.Server{Addr: addr, Handler: handler, ReadHeaderTimeout: 10 * time.Second, ReadTimeout: readTimeout, WriteTimeout: writeTimeout, IdleTimeout: 30 * time.Second}
}
