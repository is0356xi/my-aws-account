# tfvarsの変数
variable "MyIp" {}

# 環境固有の変数
variable "env_params" {
  default = {
    tag = {
      Name = "env"
    }
  }
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

    # プライベートサブネット
    privatesubnet_for_dbserver = {
      vpc_name          = "vpc_for_securitytest"
      cidr_block        = "10.1.1.0/24"
      availability_zone = "ap-northeast-1a"
    }

    # 開発用プライベートサブネット
    privatesubnet_for_devserver = {
      vpc_name          = "vpc_for_securitytest"
      cidr_block        = "10.1.100.0/24"
      availability_zone = "ap-northeast-1a"
    }
  }
}

# セキュリティグループのパラメータ
variable "sg_params" {
  default = {
    parent = {
      # 開発サーバ用のセキュリティグループ
      sg_for_devserver = {
        name        = "sg_for_devserver"
        description = "Allow ICMP for test-ping"
        vpc_name    = "vpc_for_securitytest"

        rules_ingress = {
          allow_ping = {
            from_port   = -1
            to_port     = -1
            protocol    = "ICMP"
            cidr_blocks = ["MyIp"]
            sg_names    = null
          }
        }
      }
    }

    child = {
      # VPCエンドポイント用のセキュリティグループ
      sg_for_vpcendpoint = {
        name        = "sg_for_vpcendpoint"
        description = "Allow TCP Inbound from Target Subnet of VPC-Endpoint"
        vpc_name    = "vpc_for_securitytest"

        rules_ingress = {
          allow_subnet_inbound = {
            from_port   = 443
            to_port     = 443
            protocol    = "TCP"
            cidr_blocks = null
            sg_names    = ["sg_for_devserver"]
          }
        }
      }

      # Webサーバ用のセキュリティグループ
      sg_for_webserver = {
        name        = "sg_for_webserver"
        description = "Allow HTTP and Internal-SSH"
        vpc_name    = "vpc_for_securitytest"

        rules_ingress = {
          allow_ssh = {
            from_port = 22
            to_port   = 22
            protocol  = "TCP"
            ## 踏み台(開発用サーバ)を使用する場合
            cidr_blocks = null
            sg_names    = ["sg_for_devserver"]
            ## 直接SSHする場合
            # cidr_blocks = ["MyIp"]
            # sg_names    = null
          }
          allow_http = {
            from_port   = 5000
            to_port     = 5000
            protocol    = "TCP"
            cidr_blocks = ["MyIp"]
            sg_names    = null
          }
        }
      }
    }

    grandchild = {
      # DBサーバ用のセキュリティグループ
      sg_for_dbserver = {
        name        = "sg_for_dbserver"
        description = "Allow Internal-MySQL and Internal-SSH"
        vpc_name    = "vpc_for_securitytest"

        rules_ingress = {
          allow_ssh = {
            from_port = 22
            to_port   = 22
            protocol  = "TCP"
            ## 踏み台(開発用サーバ)を使用する場合
            cidr_blocks = null
            sg_names    = ["sg_for_devserver"]
            ## 直接SSHする場合
            # cidr_blocks = ["MyIp"]
            # sg_names    = null
          }
          allow_mysql = {
            from_port   = 3306
            to_port     = 3306
            protocol    = "TCP"
            cidr_blocks = null
            sg_names    = ["sg_for_webserver", "sg_for_devserver"]
          }
        }
      }
    }
  }
}


# IAMインスタンスプロファイル用のIAMロールのパラメータ
variable "role_params" {
  default = {
    allow-ec2-to-ssm = {
      role_name        = "allow-ec2-to-ssm"
      assume_role_file = "assumerole_for_ec2.json"
      policy_type      = "managed" # managed or file
      policy_name      = "AmazonSSMManagedInstanceCore"
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
        key_name                    = "keypair-for-webapp"
        user_data                   = "app_setup_AL2.sh"
        role_name                   = null
      }
    }

    # データベース用インスタンス
    db = {
      DB-Server = {
        ami                         = "ami-0cd0830ef4d2de449" # RHEL
        availability_zone           = "ap-northeast-1a"
        instance_type               = "t2.micro"
        associate_public_ip_address = true
        subnet_name                 = "privatesubnet_for_dbserver"
        security_group_names        = ["sg_for_dbserver"]
        source_dest_check           = null
        key_name                    = "keypair-for-webapp"
        user_data                   = "db_setup_RHEL.sh"
        role_name                   = null
      }
    }

    # 開発用インスタンス
    dev = {
      Dev-Server = {
        ami                         = "ami-02a2700d37baeef8b" # AL2
        availability_zone           = "ap-northeast-1a"
        instance_type               = "t2.micro"
        associate_public_ip_address = false
        subnet_name                 = "privatesubnet_for_devserver"
        security_group_names        = ["sg_for_devserver"]
        source_dest_check           = null
        key_name                    = "keypair-for-webapp"
        user_data                   = null
        role_name                   = "allow-ec2-to-ssm"
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

    # DBサーバが必要なパッケージをinstallする時のアウトバウンド用
    rtb_for_dbserver = {
      name = "rtb_for_dbserver"

      vpc_name    = "vpc_for_securitytest"
      subnet_name = "privatesubnet_for_dbserver"

      routes = {
        for_igw = {
          destination = "0.0.0.0/0"
          type_dst    = "gateway"
          next_hop    = "igw_for_webserver"
        }
      }
    }

    # S3のGateway型エンドポイント用のルートテーブル (SSMエージェント更新用)
    rtb_for_s3endpoint = {
      name = "rtb_for_s3endpoint"

      vpc_name    = "vpc_for_securitytest"
      subnet_name = "privatesubnet_for_devserver"

      routes = {}
    }
  }
}


# VPCエンドポイントのパラメータ
variable "vpc_endpoint_params" {
  default = {
    ec2_messages = {
      service_name      = "com.amazonaws.ap-northeast-1.ec2messages"
      vpc_endpoint_type = "Interface"

      vpc_name             = "vpc_for_securitytest"
      subnet_names         = ["privatesubnet_for_devserver"]
      security_group_names = ["sg_for_vpcendpoint"]
      private_dns_enabled  = true
    }

    ssm = {
      service_name      = "com.amazonaws.ap-northeast-1.ssm"
      vpc_endpoint_type = "Interface"

      vpc_name             = "vpc_for_securitytest"
      subnet_names         = ["privatesubnet_for_devserver"]
      security_group_names = ["sg_for_vpcendpoint"]
      private_dns_enabled  = true
    }

    ssm_messages = {
      service_name      = "com.amazonaws.ap-northeast-1.ssmmessages"
      vpc_endpoint_type = "Interface"

      vpc_name             = "vpc_for_securitytest"
      subnet_names         = ["privatesubnet_for_devserver"]
      security_group_names = ["sg_for_vpcendpoint"]
      private_dns_enabled  = true
    }

    s3 = {
      service_name      = "com.amazonaws.ap-northeast-1.s3"
      vpc_endpoint_type = "Gateway"

      vpc_name            = "vpc_for_securitytest"
      rtb_names           = ["rtb_for_s3endpoint", "rtb_for_webserver"]
      private_dns_enabled = false
    }
  }
}