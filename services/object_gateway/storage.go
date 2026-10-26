package main

import (
	"bytes"
	"context"
	"errors"
	"io"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/aws/smithy-go"
)

type s3API interface {
	PutObject(context.Context, *s3.PutObjectInput, ...func(*s3.Options)) (*s3.PutObjectOutput, error)
	GetObject(context.Context, *s3.GetObjectInput, ...func(*s3.Options)) (*s3.GetObjectOutput, error)
	HeadObject(context.Context, *s3.HeadObjectInput, ...func(*s3.Options)) (*s3.HeadObjectOutput, error)
	DeleteObject(context.Context, *s3.DeleteObjectInput, ...func(*s3.Options)) (*s3.DeleteObjectOutput, error)
	ListObjectVersions(context.Context, *s3.ListObjectVersionsInput, ...func(*s3.Options)) (*s3.ListObjectVersionsOutput, error)
}
type s3Bucket struct {
	client          s3API
	name            string
	allowAWSErasure bool
}

func (b *s3Bucket) put(ctx context.Context, key string, data []byte, contentType, checksum string) error {
	_, err := b.client.PutObject(ctx, &s3.PutObjectInput{Bucket: aws.String(b.name), Key: aws.String(key), Body: bytes.NewReader(data), ContentLength: aws.Int64(int64(len(data))), ContentType: aws.String(contentType), Metadata: map[string]string{"checksum-sha256": checksum}})
	return err
}
func storageError(err error) error {
	var e smithy.APIError
	if errors.As(err, &e) && (e.ErrorCode() == "NoSuchKey" || e.ErrorCode() == "NotFound" || e.ErrorCode() == "404") {
		return errNotFound
	}
	return err
}
func (b *s3Bucket) get(ctx context.Context, key string) (storedObject, error) {
	o, err := b.client.GetObject(ctx, &s3.GetObjectInput{Bucket: aws.String(b.name), Key: aws.String(key)})
	if err != nil {
		return storedObject{}, storageError(err)
	}
	return storedObject{body: o.Body, size: aws.ToInt64(o.ContentLength), contentType: aws.ToString(o.ContentType), checksum: o.Metadata["checksum-sha256"]}, nil
}
func (b *s3Bucket) head(ctx context.Context, key string) (storedObject, error) {
	o, err := b.client.HeadObject(ctx, &s3.HeadObjectInput{Bucket: aws.String(b.name), Key: aws.String(key)})
	if err != nil {
		return storedObject{}, storageError(err)
	}
	return storedObject{body: io.NopCloser(bytes.NewReader(nil)), size: aws.ToInt64(o.ContentLength), contentType: aws.ToString(o.ContentType), checksum: o.Metadata["checksum-sha256"]}, nil
}

// No ledger currently proves whether replication was ever enabled for a key.
// Checking today's bucket configuration cannot exclude historical replicas.
func (b *s3Bucket) delete(context.Context, string) error {
	return errors.New("replica lifetime provenance unavailable")
}
