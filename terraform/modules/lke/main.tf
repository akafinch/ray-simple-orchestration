resource "linode_lke_cluster" "this" {
  label       = var.cluster_label
  k8s_version = var.k8s_version
  region      = var.region
  tier        = var.tier

  control_plane {
    acl {
      enabled = true
      addresses {
        ipv4 = var.control_plane_acl_ips
      }
    }
  }

  # CPU pool — Ray head, Prometheus, Grafana, demo app
  pool {
    type  = var.cpu_node_type
    count = var.cpu_node_count

    labels = {
      "workload" = "system"
    }
  }

  # GPU pool — Ray workers (CLIP/CLAP inference)
  pool {
    type  = var.gpu_node_type
    count = var.gpu_node_count

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
