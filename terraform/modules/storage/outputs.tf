output "bucket_name" {
  description = "Object Storage bucket label"
  value       = linode_object_storage_bucket.model_weights.label
}

output "endpoint" {
  description = "S3-compatible endpoint URL"
  value       = "https://${linode_object_storage_bucket.model_weights.s3_endpoint}"
}

output "reader_access_key" {
  description = "Read-only access key"
  value       = linode_object_storage_key.model_reader.access_key
  sensitive   = true
}

output "reader_secret_key" {
  description = "Read-only secret key"
  value       = linode_object_storage_key.model_reader.secret_key
  sensitive   = true
}

output "writer_access_key" {
  description = "Read-write access key"
  value       = linode_object_storage_key.model_writer.access_key
  sensitive   = true
}

output "writer_secret_key" {
  description = "Read-write secret key"
  value       = linode_object_storage_key.model_writer.secret_key
  sensitive   = true
}
