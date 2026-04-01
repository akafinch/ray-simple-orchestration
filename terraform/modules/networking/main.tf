resource "linode_vpc" "main" {
  label  = "${var.cluster_label}-vpc"
  region = var.region
}

resource "linode_vpc_subnet" "cluster" {
  vpc_id = linode_vpc.main.id
  label  = "${var.cluster_label}-subnet"
  ipv4   = var.vpc_cidr
}

resource "linode_firewall" "lke" {
  label = "${var.cluster_label}-fw"

  # NodeBalancer passthrough for demo app
  inbound {
    label    = "allow-http"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "80"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }

  inbound {
    label    = "allow-https"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "443"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }

  # Kubernetes API — operator IPs only
  dynamic "inbound" {
    for_each = length(var.operator_ips) > 0 ? [1] : []
    content {
      label    = "allow-k8s-api"
      action   = "ACCEPT"
      protocol = "TCP"
      ports    = "6443"
      ipv4     = var.operator_ips
    }
  }

  # Grafana — operator IPs only
  dynamic "inbound" {
    for_each = length(var.operator_ips) > 0 ? [1] : []
    content {
      label    = "allow-grafana"
      action   = "ACCEPT"
      protocol = "TCP"
      ports    = "3000"
      ipv4     = var.operator_ips
    }
  }

  # Allow all intra-VPC traffic
  inbound {
    label    = "allow-vpc-internal"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "1-65535"
    ipv4     = [var.vpc_cidr]
  }

  inbound {
    label    = "allow-vpc-internal-udp"
    action   = "ACCEPT"
    protocol = "UDP"
    ports    = "1-65535"
    ipv4     = [var.vpc_cidr]
  }

  inbound_policy  = "DROP"
  outbound_policy = "ACCEPT"
}
