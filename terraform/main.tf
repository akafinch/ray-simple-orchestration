module "networking" {
  source = "./modules/networking"

  region        = var.region
  cluster_label = var.cluster_label
  operator_ips  = var.operator_ips
}

module "lke" {
  source = "./modules/lke"

  region         = var.region
  cluster_label  = var.cluster_label
  k8s_version    = var.k8s_version
  cpu_node_type  = var.cpu_node_type
  cpu_node_count = var.cpu_node_count
  gpu_node_type  = var.gpu_node_type
  gpu_node_count = var.gpu_node_count
  vpc_id         = module.networking.vpc_id
  subnet_id      = module.networking.subnet_id
  firewall_id    = module.networking.firewall_id
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
