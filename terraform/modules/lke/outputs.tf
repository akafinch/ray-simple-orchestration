output "kubeconfig" {
  description = "Base64-encoded kubeconfig"
  value       = linode_lke_cluster.this.kubeconfig
  sensitive   = true
}

output "kubeconfig_host" {
  description = "Kubernetes API server host"
  value       = yamldecode(base64decode(linode_lke_cluster.this.kubeconfig)).clusters[0].cluster.server
}

output "kubeconfig_token" {
  description = "Kubernetes API bearer token"
  value       = yamldecode(base64decode(linode_lke_cluster.this.kubeconfig)).users[0].user.token
  sensitive   = true
}

output "kubeconfig_ca" {
  description = "Base64-encoded cluster CA certificate"
  value       = yamldecode(base64decode(linode_lke_cluster.this.kubeconfig)).clusters[0].cluster.certificate-authority-data
}

output "cluster_id" {
  description = "LKE cluster ID"
  value       = linode_lke_cluster.this.id
}
