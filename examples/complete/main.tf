provider "tencentcloud" {
  region  = var.region
}

locals {
  account_id = "your account id"
  bucket_name = "your bucket name"
  appid = "your appid"
  bucket = "${local.bucket_name}-${local.appid}"
}

module "cloud_audit" {
  source = "../.."

  create_track = true
  create_bucket = true
  create_bucket_policy = true

  track_name = "tfmodule_audit"
  bucket_name = local.bucket_name
  appid = local.appid
  storage_prefix = "tfmodule"
  region = var.region
  
  force_clean = true
  versioning_enable = true

  lifecycle_rules = [
    {
      filter_prefix = "tf"
      transition = [{
        days = 100
        storage_class = "STANDARD_IA"
      }]
    }
  ]

   policy = <<EOF
{
  "version": "2.0",
  "Statement": [
    {
      "Principal": {
        "qcs": [
          "qcs::cam::uin/${local.account_id}:uin/${local.account_id}"
        ]
      },
      "Action": [
        "name/cos:DeleteBucket",
        "name/cos:PutBucketACL"
      ],
      "Effect": "allow",
      "Resource": [
        "qcs::cos:${var.region}:uid/${local.appid}:${local.bucket}/*"
      ]
    }
  ]
}
EOF
}