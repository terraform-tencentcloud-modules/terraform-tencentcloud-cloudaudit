locals {
  bucket = "${var.bucket_name}-${var.appid}"
}

resource "tencentcloud_audit_track" "cloudaudit" {
  count = var.create_track ? 1 : 0

  name = var.track_name
  action_type = var.action_type
  event_names = var.event_names
  resource_type = var.resource_type
  status = var.status
  storage {
    storage_name = var.bucket_name
    storage_prefix = var.storage_prefix
    storage_region = var.region
    storage_type = var.storage_type
  }
  track_for_all_members = var.track_for_all_members

  depends_on = [ 
    tencentcloud_cos_bucket.cos
   ]
}

resource "tencentcloud_cos_bucket" "cos" {
  count = var.create_bucket ? 1 : 0

  bucket   = local.bucket
  acl      = var.bucket_acl
  acl_body = var.acl_body
  encryption_algorithm = var.encryption_algorithm
  force_clean          = var.force_clean

  dynamic "lifecycle_rules" {
    for_each = var.lifecycle_rules
    content {
      filter_prefix = lookup(lifecycle_rules.value, "filter_prefix", "")

      dynamic "expiration" {
        for_each = lookup(lifecycle_rules.value, "expiration", [])
        content {
          date = lookup(expiration.value, "date", null)
          days = lookup(expiration.value, "days", null)
        }
      }

      dynamic "transition" {
        for_each = lookup(lifecycle_rules.value, "transition", [])
        content {
          storage_class = lookup(transition.value, "storage_class", null)
          date          = lookup(transition.value, "date", null)
          days          = lookup(transition.value, "days", null)
        }
      }
    }
  }
  tags = var.tags
}

resource "tencentcloud_cos_bucket_policy" "cos_policy" {
  count = var.create_bucket_policy ? 1 : 0

  bucket = local.bucket
  policy = var.policy
}