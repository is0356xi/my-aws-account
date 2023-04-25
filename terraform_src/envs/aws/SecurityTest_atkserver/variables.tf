# tfvarsの変数
variable "MyIp" {}

variable env_params{
  default = null
}

# VPCのパラメータ
variable "vpc_params" {
  default = {
    # トラフィック検査用VPC
    vpc_for_securitytest = {
      cidr_block           = "10.1.0.0/16"
      enable_dns_hostnames = true
      enable_dns_support   = true
    }
  }
}

# インターネットゲートウェイのパラメータ
variable "igw_params" {
  default = {
    # WebServer用インターネットゲートウェイ
    igw_for_webserver = {
      vpc_name = "vpc_for_securitytest"
    }
  }
}

# サブネットのパラメータ
variable "subnet_params" {
  default = {
    # パブリックサブネット
    publicsubnet_for_webserver = {
      vpc_name          = "vpc_for_securitytest"
      cidr_block        = "10.1.0.0/24"
      availability_zone = "ap-northeast-1a"
    }
  }
}

# セキュリティグループのパラメータ
variable "sg_params" {
  default = {
    
    sg_for_webserver = {
      name        = "sg_for_webserver"
      description = "Allow HTTP and Internal-SSH"
      vpc_name    = "vpc_for_securitytest"

      rules_ingress = {
        allow_ssh = {
          from_port = 22
          to_port   = 22
          protocol  = "TCP"
          cidr_blocks = ["MyIp"]
          sg_names    = null
        }
        allow_http = {
          from_port   = 5000
          to_port     = 5000
          protocol    = "TCP"
          cidr_blocks = ["0.0.0.0/0"]
          sg_names    = null
        }
      }
    }
  }
}


# EC2インスタンスのパラメータ
variable "ec2_params" {
  default = {
    # WEBサーバ用インスタンス
    web = {
      Web-Server = {
        ami                         = "ami-02a2700d37baeef8b" # AL2
        availability_zone           = "ap-northeast-1a"
        instance_type               = "t2.micro"
        associate_public_ip_address = true
        subnet_name                 = "publicsubnet_for_webserver"
        security_group_names        = ["sg_for_webserver"]
        source_dest_check           = null
        key_name                    = "keypair-for-securitytest"
        user_data                   = "app_setup_AL2.sh"
        role_name                   = null
      }
    }
  }
}

# ルートテーブルのパラメータ
variable "rtb_params" {
  default = {
    # WEBサーバのインターネットゲートウェイ向きのトラフィック用
    rtb_for_webserver = {
      name = "rtb_for_webserver"

      vpc_name    = "vpc_for_securitytest"
      subnet_name = "publicsubnet_for_webserver"

      routes = {
        for_igw = {
          destination = "0.0.0.0/0"
          type_dst    = "gateway"
          next_hop    = "igw_for_webserver"
        }
      }
    }
  }
}