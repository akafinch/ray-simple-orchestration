variable "region" {
  description = "Linode region"
  type        = string
}

variable "cluster_label" {
  description = "LKE cluster label"
  type        = string
}

variable "k8s_version" {
  description = "Kubernetes version (omit to auto-select latest available)"
  type        = string
  default     = null
}

variable "tier" {
  description = "LKE tier: 'standard' or 'enterprise'"
  type        = string
  default     = "enterprise"
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

variable "control_plane_acl_ips" {
  description = "CIDR blocks allowed to reach the Kubernetes API control plane (enterprise only)"
  type        = list(string)
  default     = []
}
