output "kubeconfig" {
  description = "Base64-encoded kubeconfig"
  value       = linode_lke_cluster.this.kubeconfig
  sensitive   = true
}

output "cluster_id" {
  description = "LKE cluster ID"
  value       = linode_lke_cluster.this.id
}
