variable "region" {
  description = "Linode region"
  type        = string
}

variable "cluster_label" {
  description = "LKE cluster label"
  type        = string
}

variable "k8s_version" {
  description = "Kubernetes version"
  type        = string
}

variable "cpu_node_type" {
  description = "Linode type for CPU nodes"
  type        = string
}

variable "cpu_node_count" {
  description = "Number of CPU nodes"
  type        = number
}

variable "gpu_node_type" {
  description = "Linode type for GPU nodes"
  type        = string
}

variable "gpu_node_count" {
  description = "Number of GPU nodes"
  type        = number
}

variable "vpc_id" {
  description = "VPC ID to attach the cluster to"
  type        = string
}

variable "subnet_id" {
  description = "VPC subnet ID for the cluster"
  type        = string
}

variable "firewall_id" {
  description = "Cloud Firewall ID for node pools"
  type        = string
}
