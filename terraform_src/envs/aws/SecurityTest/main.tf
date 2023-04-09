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


# セキュリティグループの作成 (親子関係を考慮)
module "securitygroup" {
  source = "../../../modules/VPC/securitygroups"

  sg_params   = var.sg_params.parent
  MyIp        = var.MyIp
  created_vpc = module.network.created_vpc
  created_sg  = null

  depends_on = [module.network]
}

module "securitygroup_child" {
  source = "../../../modules/VPC/securitygroups"

  sg_params   = var.sg_params.child
  MyIp        = var.MyIp
  created_vpc = module.network.created_vpc
  created_sg  = module.securitygroup.created_sg

  depends_on = [module.network]
}

module "securitygroup_grandchild" {
  source = "../../../modules/VPC/securitygroups"

  sg_params   = var.sg_params.grandchild
  MyIp        = var.MyIp
  created_vpc = module.network.created_vpc
  created_sg = merge(
    module.securitygroup.created_sg,
    module.securitygroup_child.created_sg,
  )


  depends_on = [module.network]
}

module "securitygroup_great_grandchild" {
  source = "../../../modules/VPC/securitygroups"

  sg_params   = var.sg_params.great_grandchild
  MyIp        = var.MyIp
  created_vpc = module.network.created_vpc
  created_sg = merge(
    module.securitygroup.created_sg,
    module.securitygroup_child.created_sg,
    module.securitygroup_grandchild.created_sg,
  )

  depends_on = [module.network]
}

locals {
  created_sg = merge(
    module.securitygroup.created_sg,
    module.securitygroup_child.created_sg,
    module.securitygroup_grandchild.created_sg,
    module.securitygroup_great_grandchild.created_sg,
  )
}

# インスタンスの作成
module "ec2" {
  source     = "../../../modules/EC2/instances"
  env_params = var.env_params

  ec2_params     = var.ec2_params
  created_subnet = module.network.created_subnet
  created_sg     = local.created_sg

  depends_on = [module.network, module.securitygroup]

}

# インスタンスにElasticIPを付与
module "add_elasticip" {
  source = "../../../modules/VPC/elasticip"

  # ENI・ElasticIPのパラメータ
  eni_params = var.eni_params
  eip_params = var.eip_params

  # 作成済みのリソース
  created_vpc    = module.network.created_vpc
  created_subnet = module.network.created_subnet
  created_sg     = local.created_sg
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

  depends_on = [module.network, module.igw]
}


# VPCエンドポイントの作成
module "vpc_endpoint" {
  source = "../../../modules/VPC/endpoints"

  vpc_endpoint_params = var.vpc_endpoint_params

  created_vpc    = module.network.created_vpc
  created_subnet = module.network.created_subnet
  created_sg     = local.created_sg

  depends_on = [module.network, module.securitygroup]
}


# output "debug" {
#   value = module.securitygroup.created_sg
# }