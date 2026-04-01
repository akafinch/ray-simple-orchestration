variable "region" {
  description = "Linode region"
  type        = string
}

variable "cluster_label" {
  description = "Label prefix for networking resources"
  type        = string
}

variable "vpc_cidr" {
  description = "IPv4 CIDR for the VPC subnet"
  type        = string
  default     = "10.0.0.0/16"
}

variable "operator_ips" {
  description = "CIDR blocks for operator access to K8s API and Grafana"
  type        = list(string)
  default     = []
}
