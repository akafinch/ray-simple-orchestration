resource "linode_object_storage_bucket" "model_weights" {
  cluster = var.obj_storage_region
  label   = var.model_bucket_label
  acl     = "private"
}

resource "linode_object_storage_key" "model_reader" {
  label = "${var.model_bucket_label}-reader"

  bucket_access {
    bucket_name = linode_object_storage_bucket.model_weights.label
    cluster     = var.obj_storage_region
    permissions = "read_only"
  }
}

resource "linode_object_storage_key" "model_writer" {
  label = "${var.model_bucket_label}-writer"

  bucket_access {
    bucket_name = linode_object_storage_bucket.model_weights.label
    cluster     = var.obj_storage_region
    permissions = "read_write"
  }
}
