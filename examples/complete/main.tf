provider "tencentcloud" {
  region  = var.region
}

module "cloud_audit" {
  source = "../.."

  create_track = true
  create_bucket = true

  track_name = "tfmodule_audit"
  bucket_name = "tf-cos"
  appid = "your appid"
  storage_prefix = "tfmodule"
  region = var.region
  
  force_clean = true
  lifecycle_rules = [
    {
      filter_prefix = "tf"
      transition = [{
        days = 100
        storage_class = "STANDARD_IA"
      }]
    }
  ]
}