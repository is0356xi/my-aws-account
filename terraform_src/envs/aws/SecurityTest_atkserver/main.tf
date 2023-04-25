# VPC・サブネットの作成
module "network" {
  source = "../../../modules/VPC/vpc_subnet"

  vpc_params    = var.vpc_params
  subnet_params = var.subnet_params
}


# インターネットゲートウェイの作成
module "igw" {
  source = "../../../modules/VPC/internetgateways"

  igw_params  = var.igw_params
  created_vpc = module.network.created_vpc

  depends_on = [module.network]
}


# セキュリティグループの作成
module "securitygroup" {
  source = "../../../modules/VPC/securitygroups"

  sg_params   = var.sg_params
  MyIp        = var.MyIp
  created_vpc = module.network.created_vpc
  created_sg  = null

  depends_on = [module.network]
}


# WEBサーバ用インスタンスの作成
module "web_server" {
  source     = "../../../modules/EC2/instances"
  env_params = var.env_params

  ec2_params     = var.ec2_params.web
  created_subnet = module.network.created_subnet
  created_sg     = module.securitygroup.created_sg
  user_data_vars = var.user_data_vars
  created_role   = null

  depends_on = [module.network, module.securitygroup]
}


# ルートテーブルの作成
locals {
  dst_resources = {
    # 作成済みのIGW
    gateway = module.igw.created_igw
  }
}

module "routetable" {
  source = "../../../modules/VPC/routetables"

  rtb_params = var.rtb_params

  created_vpc    = module.network.created_vpc
  created_subnet = module.network.created_subnet
  dst_resources  = local.dst_resources

  depends_on = [module.network, module.igw]
}