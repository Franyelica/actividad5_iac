module "network" {
  source = "./modules/network"

  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  app_port             = var.app_port
}

module "data" {
  source = "./modules/data"

  project_name       = var.project_name
  private_subnet_ids = module.network.private_subnet_ids
  db_sg_id           = module.network.db_sg_id
  cache_sg_id        = module.network.cache_sg_id
  db_name            = var.db_name
  db_username        = var.db_username
  db_password        = var.db_password
}

module "compute" {
  source = "./modules/compute"

  project_name      = var.project_name
  aws_region        = var.aws_region
  app_port          = var.app_port
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  alb_sg_id         = module.network.alb_sg_id
  app_sg_id         = module.network.app_sg_id

  db_host     = module.data.db_host
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password
  redis_host  = module.data.redis_host

  moodle_admin_password = var.moodle_admin_password
}
