module "network" {
  source      = "../../modules/network"
  project     = var.project
  environment = var.environment
}

module "app" {
  source      = "../../modules/app"
  project     = var.project
  environment = var.environment

  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  lambda_sg_id       = module.network.lambda_sg_id
  rds_sg_id          = module.network.rds_sg_id
}
