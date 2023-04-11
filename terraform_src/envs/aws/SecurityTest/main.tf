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


# セキュリティグループの作成 (親)
module "securitygroup" {
  source = "../../../modules/VPC/securitygroups"

  sg_params   = var.sg_params.parent
  MyIp        = var.MyIp
  created_vpc = module.network.created_vpc
  created_sg  = null

  depends_on = [module.network]
}

# セキュリティグループの作成 (子)
module "securitygroup_child" {
  source = "../../../modules/VPC/securitygroups"

  sg_params   = var.sg_params.child
  MyIp        = var.MyIp
  created_vpc = module.network.created_vpc
  created_sg  = module.securitygroup.created_sg

  depends_on = [module.network, module.securitygroup]
}

# セキュリティグループの作成 (孫)
module "securitygroup_grandchild" {
  source = "../../../modules/VPC/securitygroups"

  sg_params   = var.sg_params.grandchild
  MyIp        = var.MyIp
  created_vpc = module.network.created_vpc
  created_sg = merge(
    module.securitygroup.created_sg,
    module.securitygroup_child.created_sg,
  )


  depends_on = [module.securitygroup_child]
}


locals {
  created_sg = merge(
    module.securitygroup.created_sg,
    module.securitygroup_child.created_sg,
    module.securitygroup_grandchild.created_sg,
  )
}


# IAMインスタンスプロファイル用のIAMロールを作成
module "iam_role" {
  source = "../../../modules/IAM/role"

  role_params = var.role_params
}


# WEBサーバ用インスタンスの作成
module "web_server" {
  source     = "../../../modules/EC2/instances"
  env_params = var.env_params

  ec2_params     = var.ec2_params.web
  created_subnet = module.network.created_subnet
  created_sg     = local.created_sg
  user_data_vars = var.user_data_vars
  created_role   = null

  depends_on = [module.network, module.securitygroup]
}

# DBサーバ用インスタンスの作成
module "db_server" {
  source     = "../../../modules/EC2/instances"
  env_params = var.env_params

  ec2_params     = var.ec2_params.db
  created_subnet = module.network.created_subnet
  created_sg     = local.created_sg
  user_data_vars = var.user_data_vars
  created_role   = null

  depends_on = [module.network, module.securitygroup]
}

# 開発サーバ用インスタンスの作成
module "dev_server" {
  source     = "../../../modules/EC2/instances"
  env_params = var.env_params

  ec2_params     = var.ec2_params.dev
  created_subnet = module.network.created_subnet
  created_sg     = local.created_sg
  user_data_vars = var.user_data_vars
  created_role   = module.iam_role.created_role

  depends_on = [module.network, module.securitygroup, module.iam_role]
}


# WEBサーバ用のインスタンスにElasticIPを付与
# module "add_elasticip" {
#   source = "../../../modules/VPC/elasticip"

#   # ENI・ElasticIPのパラメータ
#   eni_params = var.eni_params
#   eip_params = var.eip_params

#   # 作成済みのリソース
#   created_vpc    = module.network.created_vpc
#   created_subnet = module.network.created_subnet
#   created_sg     = local.created_sg
#   created_ec2    = module.web_server.created_ec2

#   depends_on = [module.web_server, module.securitygroup]
# }


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
  created_rtb    = module.routetable.created_rtb

  depends_on = [module.network, module.securitygroup, module.routetable]
}


output "created_servers" {
  value = {
    dev_server_instance_id = module.dev_server.created_ec2["Dev-Server"].id
    db_server_private_ip   = module.db_server.created_ec2["DB-Server"].private_ip
    # webapp_url             = "http://${module.add_elasticip.created_eip["eip_for_webserver"].public_ip}:5000"
    webapp_url = "http://${module.web_server.created_ec2["Web-Server"].public_ip}:5000"
  }
}


### デバッグ ###
# data "template_file" "user_data_test" {
#   template = file("app_setup_AL2.sh")
#   vars = {
#     vars = "\"{'host':'10.1.1.236', 'port':'3306', 'user':'test_user', 'password':'Jamadayo61!', 'database':'securitytest'}\""
#   }
# }

# output "debug" {
#   value = data.template_file.user_data_test
# }