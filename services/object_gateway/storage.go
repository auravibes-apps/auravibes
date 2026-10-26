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

// The caller has already durably fenced this key. Exact-key version deletion
// requires sole-writer access and a provider with AWS S3 version semantics.
func (b *s3Bucket) delete(ctx context.Context, key string) error {
	if !b.allowAWSErasure {
		return errors.New("provider erasure verification unavailable")
	}
	seen := map[string]bool{}
	for {
		page, err := b.client.ListObjectVersions(ctx, &s3.ListObjectVersionsInput{Bucket: aws.String(b.name), Prefix: aws.String(key)})
		if err != nil {
			return err
		}
		count := 0
		for _, item := range page.Versions {
			if aws.ToString(item.Key) == key {
				count++
				if item.VersionId == nil {
					return errors.New("missing version identity")
				}
				if seen[aws.ToString(item.VersionId)] {
					return errors.New("version deletion did not converge")
				}
				seen[aws.ToString(item.VersionId)] = true
				if _, err = b.client.DeleteObject(ctx, &s3.DeleteObjectInput{Bucket: aws.String(b.name), Key: aws.String(key), VersionId: item.VersionId}); err != nil {
					return err
				}
			}
		}
		for _, item := range page.DeleteMarkers {
			if aws.ToString(item.Key) == key {
				count++
				if item.VersionId == nil {
					return errors.New("missing version identity")
				}
				if seen[aws.ToString(item.VersionId)] {
					return errors.New("version deletion did not converge")
				}
				seen[aws.ToString(item.VersionId)] = true
				if _, err = b.client.DeleteObject(ctx, &s3.DeleteObjectInput{Bucket: aws.String(b.name), Key: aws.String(key), VersionId: item.VersionId}); err != nil {
					return err
				}
			}
		}
		if count == 0 {
			if aws.ToBool(page.IsTruncated) {
				return errors.New("unverifiable version listing")
			}
			break
		}
	}
	// A versionless provider response is not sufficient; check current object too.
	_, err := b.client.HeadObject(ctx, &s3.HeadObjectInput{Bucket: aws.String(b.name), Key: aws.String(key)})
	if errors.Is(storageError(err), errNotFound) {
		return nil
	}
	if err != nil {
		return err
	}
	return errors.New("object still exists")
}
