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

type fakeBucketAuditAPI struct {
	replication          *s3.GetBucketReplicationOutput
	replicationErr       error
	versioning           *s3.GetBucketVersioningOutput
	versioningErr        error
	objectLock           *s3.GetObjectLockConfigurationOutput
	objectLockErr        error
	lifecycle            *s3.GetBucketLifecycleConfigurationOutput
	lifecycleErr         error
	ownership            *s3.GetBucketOwnershipControlsOutput
	ownershipErr         error
	publicAccess         *s3.GetPublicAccessBlockOutput
	publicAccessErr      error
	versions             []*s3.ListObjectVersionsOutput
	versionsErr          error
	versionListCallCount int
}

func (f *fakeBucketAuditAPI) GetBucketReplication(context.Context, *s3.GetBucketReplicationInput, ...func(*s3.Options)) (*s3.GetBucketReplicationOutput, error) {
	return f.replication, f.replicationErr
}
func (f *fakeBucketAuditAPI) GetBucketVersioning(context.Context, *s3.GetBucketVersioningInput, ...func(*s3.Options)) (*s3.GetBucketVersioningOutput, error) {
	return f.versioning, f.versioningErr
}
func (f *fakeBucketAuditAPI) GetObjectLockConfiguration(context.Context, *s3.GetObjectLockConfigurationInput, ...func(*s3.Options)) (*s3.GetObjectLockConfigurationOutput, error) {
	return f.objectLock, f.objectLockErr
}
func (f *fakeBucketAuditAPI) GetBucketLifecycleConfiguration(context.Context, *s3.GetBucketLifecycleConfigurationInput, ...func(*s3.Options)) (*s3.GetBucketLifecycleConfigurationOutput, error) {
	return f.lifecycle, f.lifecycleErr
}
func (f *fakeBucketAuditAPI) GetBucketOwnershipControls(context.Context, *s3.GetBucketOwnershipControlsInput, ...func(*s3.Options)) (*s3.GetBucketOwnershipControlsOutput, error) {
	return f.ownership, f.ownershipErr
}
func (f *fakeBucketAuditAPI) GetPublicAccessBlock(context.Context, *s3.GetPublicAccessBlockInput, ...func(*s3.Options)) (*s3.GetPublicAccessBlockOutput, error) {
	return f.publicAccess, f.publicAccessErr
}
func (f *fakeBucketAuditAPI) ListObjectVersions(context.Context, *s3.ListObjectVersionsInput, ...func(*s3.Options)) (*s3.ListObjectVersionsOutput, error) {
	f.versionListCallCount++
	if f.versionsErr != nil {
		return nil, f.versionsErr
	}
	if len(f.versions) == 0 {
		return &s3.ListObjectVersionsOutput{}, nil
	}
	index := f.versionListCallCount - 1
	if index >= len(f.versions) {
		index = len(f.versions) - 1
	}
	return f.versions[index], nil
}

func safeBucketAuditAPI() *fakeBucketAuditAPI {
	return &fakeBucketAuditAPI{
		versioning: &s3.GetBucketVersioningOutput{},
		lifecycle:  &s3.GetBucketLifecycleConfigurationOutput{},
		ownership: &s3.GetBucketOwnershipControlsOutput{OwnershipControls: &types.OwnershipControls{Rules: []types.OwnershipControlsRule{
			{ObjectOwnership: types.ObjectOwnershipBucketOwnerEnforced},
		}}},
		publicAccess: &s3.GetPublicAccessBlockOutput{PublicAccessBlockConfiguration: &types.PublicAccessBlockConfiguration{
			BlockPublicAcls:       aws.Bool(true),
			IgnorePublicAcls:      aws.Bool(true),
			BlockPublicPolicy:     aws.Bool(true),
			RestrictPublicBuckets: aws.Bool(true),
		}},
		replicationErr: &smithy.GenericAPIError{Code: "NoSuchReplicationConfiguration"},
		objectLockErr:  &smithy.GenericAPIError{Code: "ObjectLockConfigurationNotFoundError"},
	}
}

func TestBucketAuditPassesOnlyVerifiedEmptyFreshPosture(t *testing.T) {
	checks := auditBucket(context.Background(), safeBucketAuditAPI(), "dedicated")
	if len(checks) != 7 {
		t.Fatalf("checks = %d, want 7", len(checks))
	}
	for _, check := range checks {
		if !check.known || !check.passed {
			t.Errorf("%s: known=%t passed=%t detail=%s", check.name, check.known, check.passed, check.detail)
		}
	}
}

func TestBucketAuditFailsUnsafeCurrentConfiguration(t *testing.T) {
	tests := []struct {
		name   string
		change func(*fakeBucketAuditAPI)
	}{
		{"replication", func(f *fakeBucketAuditAPI) {
			f.replication = &s3.GetBucketReplicationOutput{ReplicationConfiguration: &types.ReplicationConfiguration{Rules: []types.ReplicationRule{{}}}}
			f.replicationErr = nil
		}},
		{"versioning", func(f *fakeBucketAuditAPI) { f.versioning.Status = types.BucketVersioningStatusSuspended }},
		{"object lock", func(f *fakeBucketAuditAPI) {
			f.objectLock = &s3.GetObjectLockConfigurationOutput{ObjectLockConfiguration: &types.ObjectLockConfiguration{}}
			f.objectLockErr = nil
		}},
		{"lifecycle", func(f *fakeBucketAuditAPI) { f.lifecycle.Rules = []types.LifecycleRule{{}} }},
		{"ownership", func(f *fakeBucketAuditAPI) {
			f.ownership.OwnershipControls.Rules[0].ObjectOwnership = types.ObjectOwnershipBucketOwnerPreferred
		}},
		{"public access", func(f *fakeBucketAuditAPI) {
			f.publicAccess.PublicAccessBlockConfiguration.BlockPublicPolicy = aws.Bool(false)
		}},
		{"object versions", func(f *fakeBucketAuditAPI) {
			f.versions = []*s3.ListObjectVersionsOutput{{Versions: []types.ObjectVersion{{}}}}
		}},
		{"delete markers", func(f *fakeBucketAuditAPI) {
			f.versions = []*s3.ListObjectVersionsOutput{{DeleteMarkers: []types.DeleteMarkerEntry{{}}}}
		}},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			client := safeBucketAuditAPI()
			tt.change(client)
			found := false
			for _, check := range auditBucket(context.Background(), client, "dedicated") {
				if check.known && !check.passed {
					found = true
				}
			}
			if !found {
				t.Fatal("unsafe configuration did not produce a known failure")
			}
		})
	}
}

func TestBucketAuditDoesNotTreatInspectionErrorsAsSafe(t *testing.T) {
	client := safeBucketAuditAPI()
	denied := errors.New("access denied")
	client.replicationErr = denied
	client.versioningErr = denied
	client.objectLockErr = denied
	client.lifecycleErr = denied
	client.ownershipErr = denied
	client.publicAccessErr = denied
	client.versionsErr = denied
	for _, check := range auditBucket(context.Background(), client, "dedicated") {
		if check.known && check.passed {
			t.Errorf("%s passed despite unavailable inspection", check.name)
		}
	}
}

func TestBucketAuditPaginatesEmptyVersionListing(t *testing.T) {
	client := safeBucketAuditAPI()
	client.versions = []*s3.ListObjectVersionsOutput{
		{IsTruncated: aws.Bool(true), NextKeyMarker: aws.String("next")},
		{},
	}
	check := auditEmpty(context.Background(), client, "dedicated")
	if !check.known || !check.passed || client.versionListCallCount != 2 {
		t.Fatalf("check = %+v; list calls = %d", check, client.versionListCallCount)
	}
}

func TestBucketAuditFailsClosedOnInvalidPagination(t *testing.T) {
	client := safeBucketAuditAPI()
	client.versions = []*s3.ListObjectVersionsOutput{{IsTruncated: aws.Bool(true)}}
	check := auditEmpty(context.Background(), client, "dedicated")
	if check.known || check.passed {
		t.Fatalf("check = %+v, want unknown", check)
	}
}
