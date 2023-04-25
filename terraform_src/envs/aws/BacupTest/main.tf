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

# RDS管理用インスタンスの作成
module "rds_manage_server" {
  source     = "../../../modules/EC2/instances"
  env_params = var.env_params

  ec2_params     = var.ec2_params.db
  created_subnet = module.network.created_subnet
  created_sg     = local.created_sg
  user_data_vars = var.user_data_vars
  created_role   = null

  depends_on = [module.network, module.securitygroup]
}

output "rdsmanageserver_ip" {
  value = {
    public_ip  = module.rds_manage_server.created_ec2["rdsmanageserver-BackupTest"].public_ip
    private_ip = module.rds_manage_server.created_ec2["rdsmanageserver-BackupTest"].private_ip
  }
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


# ALBの作成
module "lb" {
  source = "../../../modules/EC2/loadbalancer"

  lb_params            = var.lb_params
  tg_params            = var.tg_params
  tg_attachment_params = var.tg_attachment_params
  listener_params      = var.listener_params

  created_vpc    = module.network.created_vpc
  created_subnet = module.network.created_subnet
  created_eip    = null
  created_sg     = module.securitygroup.created_sg
  created_ec2    = module.web_server.created_ec2
}

output "created_resources" {
  value = {
    webserver1_ip = module.web_server.created_ec2["Web-Server1-BackupTest"].public_ip
    webserver2_ip = module.web_server.created_ec2["Web-Server2-BackupTest"].public_ip
    webapp_url    = "http://${module.lb.created_lb["ALBBackupTest"].dns_name}"
  }
}