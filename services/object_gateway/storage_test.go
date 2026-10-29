package main

import (
	"context"
	"errors"
	"testing"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/aws/aws-sdk-go-v2/service/s3/types"
	"github.com/aws/smithy-go"
)

type versionClient struct {
	versions             map[string]bool
	failList, failDelete bool
}

func (f *versionClient) PutObject(context.Context, *s3.PutObjectInput, ...func(*s3.Options)) (*s3.PutObjectOutput, error) {
	panic("unexpected")
}
func (f *versionClient) GetObject(context.Context, *s3.GetObjectInput, ...func(*s3.Options)) (*s3.GetObjectOutput, error) {
	panic("unexpected")
}
func (f *versionClient) HeadObject(context.Context, *s3.HeadObjectInput, ...func(*s3.Options)) (*s3.HeadObjectOutput, error) {
	return nil, &smithy.GenericAPIError{Code: "NotFound"}
}
func (f *versionClient) DeleteObject(_ context.Context, in *s3.DeleteObjectInput, _ ...func(*s3.Options)) (*s3.DeleteObjectOutput, error) {
	if f.failDelete {
		return nil, errors.New("locked")
	}
	delete(f.versions, aws.ToString(in.VersionId))
	return &s3.DeleteObjectOutput{}, nil
}
func (f *versionClient) ListObjectVersions(_ context.Context, in *s3.ListObjectVersionsInput, _ ...func(*s3.Options)) (*s3.ListObjectVersionsOutput, error) {
	if f.failList {
		return nil, errors.New("unsupported")
	}
	out := &s3.ListObjectVersionsOutput{}
	for id, marker := range f.versions {
		if marker {
			out.DeleteMarkers = append(out.DeleteMarkers, types.DeleteMarkerEntry{Key: in.Prefix, VersionId: aws.String(id)})
		} else {
			out.Versions = append(out.Versions, types.ObjectVersion{Key: in.Prefix, VersionId: aws.String(id)})
		}
	}
	return out, nil
}
func TestErasureRemainsBlockedWithoutReplicaHistory(t *testing.T) {
	client := &versionClient{versions: map[string]bool{"v1": false}}
	for _, enabled := range []bool{false, true} {
		b := &s3Bucket{client: client, name: "test", allowAWSErasure: enabled}
		if err := b.delete(context.Background(), "test"); err == nil || len(client.versions) != 1 {
			t.Fatal("erasure was incorrectly attested")
		}
	}
}
