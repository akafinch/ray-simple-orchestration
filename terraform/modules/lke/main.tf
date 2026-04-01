resource "linode_lke_cluster" "this" {
  label       = var.cluster_label
  k8s_version = var.k8s_version
  region      = var.region

  vpc_id    = var.vpc_id
  subnet_id = var.subnet_id

  # CPU pool — Ray head, Prometheus, Grafana, demo app
  pool {
    type        = var.cpu_node_type
    count       = var.cpu_node_count
    firewall_id = var.firewall_id

    labels = {
      "workload" = "system"
    }
  }

  # GPU pool — Ray workers (CLIP/CLAP inference)
  pool {
    type        = var.gpu_node_type
    count       = var.gpu_node_count
    firewall_id = var.firewall_id

    labels = {
      "workload"       = "inference"
      "nvidia.com/gpu" = "true"
    }

    taint {
      key    = "nvidia.com/gpu"
      value  = "true"
      effect = "NoSchedule"
    }
  }
}

# Write kubeconfig to local file for operator use
resource "local_sensitive_file" "kubeconfig" {
  content  = base64decode(linode_lke_cluster.this.kubeconfig)
  filename = "${path.root}/../kubeconfig"
}
