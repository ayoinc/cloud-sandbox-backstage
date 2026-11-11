module "sandbox" {
  source = "./modules/sandbox"

  project_id = var.project_id
  name       = var.name
  region     = var.region

  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets

  include_bastion = var.include_bastion

  include_eks                  = var.include_eks
  kubernetes_api_allowed_cidrs = var.kubernetes_api_allowed_cidrs

  include_rds = var.include_rds
}
