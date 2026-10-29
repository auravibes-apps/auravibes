package main

import (
	"context"
	"errors"
	"fmt"
	"os"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/aws/aws-sdk-go-v2/service/s3/types"
	"github.com/aws/smithy-go"
)

type bucketAuditAPI interface {
	GetBucketReplication(context.Context, *s3.GetBucketReplicationInput, ...func(*s3.Options)) (*s3.GetBucketReplicationOutput, error)
	GetBucketVersioning(context.Context, *s3.GetBucketVersioningInput, ...func(*s3.Options)) (*s3.GetBucketVersioningOutput, error)
	GetObjectLockConfiguration(context.Context, *s3.GetObjectLockConfigurationInput, ...func(*s3.Options)) (*s3.GetObjectLockConfigurationOutput, error)
	GetBucketLifecycleConfiguration(context.Context, *s3.GetBucketLifecycleConfigurationInput, ...func(*s3.Options)) (*s3.GetBucketLifecycleConfigurationOutput, error)
	GetBucketOwnershipControls(context.Context, *s3.GetBucketOwnershipControlsInput, ...func(*s3.Options)) (*s3.GetBucketOwnershipControlsOutput, error)
	GetPublicAccessBlock(context.Context, *s3.GetPublicAccessBlockInput, ...func(*s3.Options)) (*s3.GetPublicAccessBlockOutput, error)
	ListObjectVersions(context.Context, *s3.ListObjectVersionsInput, ...func(*s3.Options)) (*s3.ListObjectVersionsOutput, error)
}

type bucketAuditCheck struct {
	name   string
	passed bool
	known  bool
	detail string
}

func auditBucket(ctx context.Context, client bucketAuditAPI, bucket string) []bucketAuditCheck {
	checks := auditBucketConfiguration(ctx, client, bucket)
	return append(checks, auditEmpty(ctx, client, bucket))
}

func auditBucketConfiguration(ctx context.Context, client bucketAuditAPI, bucket string) []bucketAuditCheck {
	return []bucketAuditCheck{
		auditNoReplication(ctx, client, bucket),
		auditNeverVersioned(ctx, client, bucket),
		auditNoObjectLock(ctx, client, bucket),
		auditNoLifecycle(ctx, client, bucket),
		auditOwnership(ctx, client, bucket),
		auditPublicAccessBlock(ctx, client, bucket),
	}
}

func bucketAuditPassed(checks []bucketAuditCheck) bool {
	for _, check := range checks {
		if !check.known || !check.passed {
			return false
		}
	}
	return true
}

func auditNoReplication(ctx context.Context, client bucketAuditAPI, bucket string) bucketAuditCheck {
	out, err := client.GetBucketReplication(ctx, &s3.GetBucketReplicationInput{Bucket: aws.String(bucket)})
	if isS3Error(err, "NoSuchReplicationConfiguration") {
		return passed("replication", "no replication configuration")
	}
	if err != nil || out == nil {
		return unknown("replication", "could not verify replication configuration")
	}
	if out.ReplicationConfiguration != nil && len(out.ReplicationConfiguration.Rules) > 0 {
		return failed("replication", "replication rules are configured")
	}
	return passed("replication", "no replication rules configured")
}

func auditNeverVersioned(ctx context.Context, client bucketAuditAPI, bucket string) bucketAuditCheck {
	out, err := client.GetBucketVersioning(ctx, &s3.GetBucketVersioningInput{Bucket: aws.String(bucket)})
	if err != nil || out == nil {
		return unknown("versioning", "could not verify versioning history")
	}
	if out.Status != "" || out.MFADelete != "" {
		return failed("versioning", "bucket versioning was enabled or suspended")
	}
	return passed("versioning", "versioning has never been enabled")
}

func auditNoObjectLock(ctx context.Context, client bucketAuditAPI, bucket string) bucketAuditCheck {
	out, err := client.GetObjectLockConfiguration(ctx, &s3.GetObjectLockConfigurationInput{Bucket: aws.String(bucket)})
	if isS3Error(err, "ObjectLockConfigurationNotFoundError") {
		return passed("object lock", "no object lock configuration")
	}
	if err != nil || out == nil {
		return unknown("object lock", "could not verify object lock configuration")
	}
	if out.ObjectLockConfiguration != nil {
		return failed("object lock", "object lock is configured")
	}
	return passed("object lock", "no object lock configuration")
}

func auditNoLifecycle(ctx context.Context, client bucketAuditAPI, bucket string) bucketAuditCheck {
	out, err := client.GetBucketLifecycleConfiguration(ctx, &s3.GetBucketLifecycleConfigurationInput{Bucket: aws.String(bucket)})
	if isS3Error(err, "NoSuchLifecycleConfiguration") {
		return passed("lifecycle", "no lifecycle rules")
	}
	if err != nil || out == nil {
		return unknown("lifecycle", "could not verify lifecycle rules")
	}
	if len(out.Rules) > 0 {
		return failed("lifecycle", "lifecycle rules are configured")
	}
	return passed("lifecycle", "no lifecycle rules")
}

func auditOwnership(ctx context.Context, client bucketAuditAPI, bucket string) bucketAuditCheck {
	out, err := client.GetBucketOwnershipControls(ctx, &s3.GetBucketOwnershipControlsInput{Bucket: aws.String(bucket)})
	if err != nil || out == nil {
		return unknown("ownership", "bucket-owner-enforced ownership is not verified")
	}
	if out.OwnershipControls == nil || len(out.OwnershipControls.Rules) != 1 || out.OwnershipControls.Rules[0].ObjectOwnership != types.ObjectOwnershipBucketOwnerEnforced {
		return failed("ownership", "bucket-owner-enforced ownership is not enabled")
	}
	return passed("ownership", "bucket-owner-enforced ownership")
}

func auditPublicAccessBlock(ctx context.Context, client bucketAuditAPI, bucket string) bucketAuditCheck {
	out, err := client.GetPublicAccessBlock(ctx, &s3.GetPublicAccessBlockInput{Bucket: aws.String(bucket)})
	if err != nil || out == nil || out.PublicAccessBlockConfiguration == nil {
		return unknown("public access", "all public access blocks are not verified")
	}
	b := out.PublicAccessBlockConfiguration
	if !aws.ToBool(b.BlockPublicAcls) || !aws.ToBool(b.IgnorePublicAcls) || !aws.ToBool(b.BlockPublicPolicy) || !aws.ToBool(b.RestrictPublicBuckets) {
		return failed("public access", "one or more public access blocks are disabled")
	}
	return passed("public access", "all public access blocks enabled")
}

func auditEmpty(ctx context.Context, client bucketAuditAPI, bucket string) bucketAuditCheck {
	input := &s3.ListObjectVersionsInput{Bucket: aws.String(bucket), MaxKeys: aws.Int32(1000)}
	for page := 0; page < 1000; page++ {
		out, err := client.ListObjectVersions(ctx, input)
		if err != nil || out == nil {
			return unknown("contents", "could not verify bucket contents")
		}
		if len(out.Versions) > 0 || len(out.DeleteMarkers) > 0 {
			return failed("contents", "bucket contains object versions or delete markers")
		}
		if !aws.ToBool(out.IsTruncated) {
			return passed("contents", "bucket has no object versions or delete markers")
		}
		if out.NextKeyMarker == nil {
			return unknown("contents", "version listing pagination could not be verified")
		}
		input.KeyMarker = out.NextKeyMarker
		input.VersionIdMarker = out.NextVersionIdMarker
	}
	return unknown("contents", "version listing exceeded the audit page limit")
}

func isS3Error(err error, code string) bool {
	var api smithy.APIError
	return errors.As(err, &api) && api.ErrorCode() == code
}

func passed(name, detail string) bucketAuditCheck {
	return bucketAuditCheck{name: name, passed: true, known: true, detail: detail}
}

func failed(name, detail string) bucketAuditCheck {
	return bucketAuditCheck{name: name, known: true, detail: detail}
}

func unknown(name, detail string) bucketAuditCheck {
	return bucketAuditCheck{name: name, detail: detail}
}

func runBucketAudit(ctx context.Context) int {
	if os.Getenv("GATEWAY_ERASURE_PROVIDER") != "aws-s3" || os.Getenv("S3_ENDPOINT") != "" {
		fmt.Fprintln(os.Stderr, "FAIL: audit supports AWS S3 only; set GATEWAY_ERASURE_PROVIDER=aws-s3 and leave S3_ENDPOINT unset")
		return 2
	}
	bucket, region := os.Getenv("S3_BUCKET"), os.Getenv("AWS_REGION")
	if bucket == "" || region == "" {
		fmt.Fprintln(os.Stderr, "FAIL: S3_BUCKET and AWS_REGION are required")
		return 2
	}
	cfg, err := config.LoadDefaultConfig(ctx, config.WithRegion(region))
	if err != nil {
		fmt.Fprintln(os.Stderr, "UNKNOWN: AWS credential or region configuration unavailable")
		return 2
	}
	client := s3.NewFromConfig(cfg)
	checks := auditBucket(ctx, client, bucket)
	allPassed := true
	for _, check := range checks {
		status := "UNKNOWN"
		if check.known && check.passed {
			status = "PASS"
		} else if check.known {
			status = "FAIL"
		}
		fmt.Printf("%s: %s - %s\n", status, check.name, check.detail)
		allPassed = allPassed && check.known && check.passed
	}
	fmt.Println("NOTE: This is a current-state snapshot. It does not prove historical configuration or prevent future changes.")
	fmt.Println("NOTE: Preserve fail-closed erasure until bucket history, exclusive writer controls, and old signer/worker drain are independently verified.")
	if !allPassed {
		fmt.Println("SNAPSHOT INCOMPLETE: bucket is not verified for the approved fresh-bucket setup")
		return 1
	}
	fmt.Println("SNAPSHOT PASS: current bucket settings match the expected fresh-bucket setup")
	return 0
}
