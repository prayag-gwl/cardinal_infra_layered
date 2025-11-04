terraform { required_version = ">= 1.5.0" }

module "common" {
  source      = "../../../modules/common"
  project     = "cardinal"
  environment = "dev"
}

