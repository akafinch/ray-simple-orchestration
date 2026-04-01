output "kubeconfig" {
  description = "LKE cluster kubeconfig (base64)"
  value       = module.lke.kubeconfig
  sensitive   = true
}

output "kubeconfig_host" {
  description = "Kubernetes API server endpoint"
  value       = module.lke.kubeconfig_host
}

output "cluster_id" {
  description = "LKE cluster ID"
  value       = module.lke.cluster_id
}

output "obj_reader_key" {
  description = "Object Storage read-only access key"
  value       = module.storage.reader_access_key
  sensitive   = true
}

output "obj_reader_secret" {
  description = "Object Storage read-only secret key"
  value       = module.storage.reader_secret_key
  sensitive   = true
}

output "obj_writer_key" {
  description = "Object Storage read-write access key (for model upload)"
  value       = module.storage.writer_access_key
  sensitive   = true
}

output "obj_writer_secret" {
  description = "Object Storage read-write secret key (for model upload)"
  value       = module.storage.writer_secret_key
  sensitive   = true
}

output "obj_endpoint" {
  description = "Object Storage S3-compatible endpoint URL"
  value       = module.storage.endpoint
}

output "model_bucket" {
  description = "Object Storage bucket name for model weights"
  value       = module.storage.bucket_name
}

output "grafana_admin_password" {
  description = "Generated Grafana admin password"
  value       = random_password.grafana_admin.result
  sensitive   = true
}
