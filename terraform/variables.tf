variable "linode_token" {
  description = "Linode API token"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "Linode region for the LKE cluster"
  type        = string
  default     = "us-ord"
}

variable "cluster_label" {
  description = "Label for the LKE cluster"
  type        = string
  default     = "clip-clap-inference"
}

variable "k8s_version" {
  description = "Kubernetes version for LKE (omit to use LKE default)"
  type        = string
  default     = null
}

variable "lke_tier" {
  description = "LKE tier: 'standard' or 'enterprise'"
  type        = string
  default     = "enterprise"
}

variable "cpu_node_type" {
  description = "Linode instance type for CPU node pool"
  type        = string
  default     = "g6-standard-4"
}

variable "cpu_node_count" {
  description = "Number of CPU nodes"
  type        = number
  default     = 2
}

variable "gpu_node_type" {
  description = "Linode instance type for GPU node pool (RTX 4000 Ada)"
  type        = string
  default     = "g2-gpu-rtx4000a1-s"
}

variable "gpu_node_count" {
  description = "Number of GPU nodes"
  type        = number
  default     = 3
}

variable "obj_storage_region" {
  description = "Linode Object Storage cluster/region"
  type        = string
  default     = "us-ord-1"
}

variable "model_bucket_label" {
  description = "Label for the model weights Object Storage bucket"
  type        = string
  default     = "clip-clap-weights"
}

variable "allowed_ips" {
  description = "CIDR blocks allowed to access the demo app via NodeBalancer"
  type        = list(string)
}

variable "control_plane_acl_ips" {
  description = "CIDR blocks allowed to reach the Kubernetes API control plane"
  type        = list(string)
}
