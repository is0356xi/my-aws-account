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
  source     = "../../../modules/VPC/securitygroups"
  env_params = var.env_params

  sg_params   = var.sg_params
  MyIp        = var.MyIp
  created_vpc = module.network.created_vpc

  depends_on = [module.network]
}


# インスタンスの作成
module "ec2" {
  source     = "../../../modules/EC2/instances"
  env_params = var.env_params

  ec2_params     = var.ec2_params
  created_subnet = module.network.created_subnet
  created_sg     = module.securitygroup.created_sg

  depends_on = [module.network, module.securitygroup]

}

# インスタンスにENIをアタッチ
module "add_port" {
  source = "../../../modules/VPC/elasticip"

  # ENI・ElasticIPのパラメータ
  eni_params = var.eni_params
  eip_params = var.eip_params

  # 作成済みのリソース
  created_vpc    = module.network.created_vpc
  created_subnet = module.network.created_subnet
  created_sg     = module.securitygroup.created_sg
  created_ec2    = module.ec2.created_ec2

  depends_on = [module.ec2, module.securitygroup]
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

  depends_on = [module.network]
}


# VPCエンドポイントの作成
module "vpc_endpoint" {
  source = "../../../modules/VPC/endpoints"

  vpc_endpoint_params = var.vpc_endpoint_params

  created_vpc    = module.network.created_vpc
  created_subnet = module.network.created_subnet
  created_sg     = module.securitygroup.created_sg

  depends_on = [module.network, module.securitygroup]
}