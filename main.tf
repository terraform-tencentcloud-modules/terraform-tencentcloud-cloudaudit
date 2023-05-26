locals {
  bucket = "${var.bucket_name}-${var.appid}"
}

data "tencentcloud_cam_roles" "default" {
  name = "CloudAudit_QCSRole"
}

data "tencentcloud_cam_policies" "default" {
  name = "QcloudAccessForCARole"
}

resource "tencentcloud_cam_role" "default" {
  count         = length(data.tencentcloud_cam_roles.default.role_list) == 0 ? 1 : 0
  name          = "CloudAudit_QCSRole"
  document      = <<EOF
  {
    "version": "2.0",
    "statement": [
      {
        "action": ["name/sts:AssumeRole"],
        "effect": "allow",
        "principal": {
          "service": "cloudaudit.cloud.tencent.com"
        }
      }
    ]
  }
  EOF
  description   = "云审计角色"
  console_login = true
}

resource "tencentcloud_cam_role_policy_attachment" "default" {
  count     = length(data.tencentcloud_cam_roles.default.role_list) == 0 ? 1 : 0
  role_id   = join(",", tencentcloud_cam_role.default.*.id)
  policy_id = data.tencentcloud_cam_policies.default.policy_list[0].policy_id
}

resource "tencentcloud_audit_track" "cloudaudit" {
  count = var.create_track ? 1 : 0

  name          = var.track_name
  action_type   = var.action_type
  event_names   = var.event_names
  resource_type = var.resource_type
  status        = var.status
  storage {
    storage_name   = var.bucket_name
    storage_prefix = var.storage_prefix
    storage_region = var.region
    storage_type   = var.storage_type
  }
  track_for_all_members = var.track_for_all_members

  depends_on = [
    tencentcloud_cos_bucket.cos,
    tencentcloud_cam_role.default,
    tencentcloud_cam_role_policy_attachment.default,
  ]
}

resource "tencentcloud_cos_bucket" "cos" {
  count = var.create_bucket ? 1 : 0

  bucket               = local.bucket
  acl                  = var.bucket_acl
  acl_body             = var.acl_body
  encryption_algorithm = var.encryption_algorithm
  force_clean          = var.force_clean
  versioning_enable    = var.versioning_enable

  dynamic "lifecycle_rules" {
    for_each = var.lifecycle_rules
    content {
      filter_prefix = lookup(lifecycle_rules.value, "filter_prefix", "")
      id            = lookup(lifecycle_rules.value, "id", "")

      dynamic "expiration" {
        for_each = lookup(lifecycle_rules.value, "expiration", [])
        content {
          date          = lookup(expiration.value, "date", null)
          days          = lookup(expiration.value, "days", null)
          delete_marker = lookup(expiration.value, "delete_marker", null)
        }
      }

      dynamic "non_current_expiration" {
        for_each = lookup(lifecycle_rules.value, "non_current_expiration", [])
        iterator = expiration
        content {
          non_current_days = lookup(expiration.value, "non_current_days", null)
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

      dynamic "non_current_transition" {
        for_each = lookup(lifecycle_rules.value, "non_current_transition", [])
        iterator = transition
        content {
          storage_class    = lookup(transition.value, "storage_class", null)
          non_current_days = lookup(transition.value, "non_current_days", null)
        }
      }
    }
  }

  log_enable        = var.log_enable
  log_prefix        = var.log_prefix
  log_target_bucket = var.log_target_bucket

  tags = var.tags
}

resource "tencentcloud_cos_bucket_policy" "cos_policy" {
  count = var.create_bucket_policy ? 1 : 0

  bucket = local.bucket
  policy = var.policy

  depends_on = [
    tencentcloud_cos_bucket.cos
  ]
}