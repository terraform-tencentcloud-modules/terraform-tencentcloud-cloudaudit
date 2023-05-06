output "cloudaudit_id" {
  value = join("", tencentcloud_audit_track.cloudaudit.*.id)
  description = "The ID of Cloud Audit Track."
}

output "bucket_id" {
  value = join("", tencentcloud_cos_bucket.cos.*.id)
  description = "The ID of COS bucket."
}