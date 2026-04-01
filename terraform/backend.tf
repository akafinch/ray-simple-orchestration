# v1: Local state. To migrate to Linode Object Storage:
# 1. Create a bucket and access keys via the storage module
# 2. Replace this block with:
#
# terraform {
#   backend "s3" {
#     bucket                      = "<your-bucket-name>"
#     key                         = "inference-network/terraform.tfstate"
#     region                      = "us-east-1"          # placeholder, ignored by Linode
#     endpoint                    = "https://<region>.linodeobjects.com"
#     access_key                  = "<LINODE_OBJ_KEY>"
#     secret_key                  = "<LINODE_OBJ_SECRET>"
#     skip_credentials_validation = true
#     skip_metadata_api_check     = true
#     skip_region_validation      = true
#     force_path_style            = true
#   }
# }
# Then run: terraform init -migrate-state

terraform {
  backend "local" {}
}
