output "vpc_id" {
  description = "VPC ID for the LKE cluster"
  value       = linode_vpc.main.id
}

output "subnet_id" {
  description = "VPC subnet ID for the LKE cluster"
  value       = linode_vpc_subnet.cluster.id
}

output "firewall_id" {
  description = "Cloud Firewall ID for LKE node pools"
  value       = linode_firewall.lke.id
}

output "vpc_cidr" {
  description = "VPC subnet CIDR (for reference in firewall rules)"
  value       = var.vpc_cidr
}
