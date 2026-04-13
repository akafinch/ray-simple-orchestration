module "lke" {
  source = "./modules/lke"

  region         = var.region
  cluster_label  = var.cluster_label
  k8s_version    = var.k8s_version
  tier           = var.lke_tier
  cpu_node_type  = var.cpu_node_type
  cpu_node_count = var.cpu_node_count
  gpu_node_type  = var.gpu_node_type
  gpu_node_count = var.gpu_node_count
}

module "storage" {
  source = "./modules/storage"

  obj_storage_region = var.obj_storage_region
  model_bucket_label = var.model_bucket_label
}

resource "random_password" "grafana_admin" {
  length  = 24
  special = true
}

# Cloud Firewall for the NodeBalancer — created here, attached by deploy.sh
# after Kubernetes creates the NodeBalancer via the LoadBalancer Service.
resource "linode_firewall" "nodebalancer" {
  label = "${var.cluster_label}-nb-fw"

  inbound {
    label    = "allow-http"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "80"
    ipv4     = var.allowed_ips
  }

  inbound {
    label    = "allow-https"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "443"
    ipv4     = var.allowed_ips
  }

  inbound_policy  = "DROP"
  outbound_policy = "ACCEPT"
}
