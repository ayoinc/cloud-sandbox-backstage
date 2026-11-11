module "sandbox" {
  source = "./modules/sandbox"

  name = var.name

  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets

  include_bastion       = var.include_bastion
  bastion_allowed_cidrs = var.bastion_allowed_cidrs

  include_eks             = var.include_eks
  kubernetes_version      = var.kubernetes_version
  eks_public_access_cidrs = var.eks_public_access_cidrs

  include_rds = var.include_rds

  tags = var.tags
}
