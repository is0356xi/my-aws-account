# MediaConnect用のVPCを作成
module "vpc" {
  # moduleの場所を指定
  source = "./modules/VPC/vpc_subnet"

  # moduleに渡す変数を指定
  vpc_params    = var.vpc_params
  subnet_params = var.subnet_params
}

# MediaConnect用のVPCにアタッチするセキュリティグループを作成
module "security_group" {
  source     = "./modules/VPC/securitygroups"

  sg_params   = var.sg_params
  created_vpc = module.vpc.created_vpc
}

# MediaConnectがVPCインタフェースを作成するためのIAMロールを作成
module "iam_role" {
  source     = "./modules/IAM/role"

  role_params = var.role_params
}

# FlowにVPCインタフェースを追加
module "vpc_if" {
  source     = "./modules/MediaConnect/add_vpc_interface"

  mc_vpcif_params = var.mc_vpcif_params
  flow_arn        = var.flow_arn

  created_sg     = module.security_group.created_sg
  created_subnet = module.vpc.created_subnet
  created_role   = module.iam_role.created_role

  depends_on = [
    module.vpc,
    module.security_group,
    module.iam_role
  ]
}