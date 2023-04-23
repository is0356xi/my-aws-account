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
    vpc_for_backuptest = {
      cidr_block           = "10.1.0.0/16"
      enable_dns_hostnames = true
      enable_dns_support   = true
    }
  }
}

# インターネットゲートウェイのパラメータ
variable "igw_params" {
  default = {
    # LB用インターネットゲートウェイ
    igw_for_lb = {
      vpc_name = "vpc_for_backuptest"
    }
  }
}

# サブネットのパラメータ
variable "subnet_params" {
  default = {
     # LB用サブネット:AZ1
    subnet_for_lb1 = {
      vpc_name          = "vpc_for_backuptest"
      cidr_block        = "10.1.0.0/24"
      availability_zone = "ap-northeast-1a"
    }

    # LB用サブネット:AZ2
    subnet_for_lb2 = {
      vpc_name          = "vpc_for_backuptest"
      cidr_block        = "10.1.1.0/24"
      availability_zone = "ap-northeast-1c"
    }

    # Webサーバ用サブネット:AZ1
    subnet_for_webserver1 = {
      vpc_name          = "vpc_for_backuptest"
      cidr_block        = "10.1.10.0/24"
      availability_zone = "ap-northeast-1a"
    }

    # Webサーバ用サブネット:AZ2
    subnet_for_webserver2 = {
      vpc_name          = "vpc_for_backuptest"
      cidr_block        = "10.1.11.0/24"
      availability_zone = "ap-northeast-1c"
    }

    # RDS管理サーバ用サブネット:AZ1
    subnet_for_rdsmanageserver = {
      vpc_name          = "vpc_for_backuptest"
      cidr_block        = "10.1.20.0/24"
      availability_zone = "ap-northeast-1a"
    }
  }
}

# セキュリティグループのパラメータ
variable "sg_params" {
  default = {
    parent = {
      # LB用のセキュリティグループ
      sg_for_lb = {
        name        = "sg_for_lb"
        description = "Allow HTTP from MyIp"
        vpc_name    = "vpc_for_backuptest"

        rules_ingress = {
          allow_http = {
            from_port   = 80
            to_port     = 80
            protocol    = "TCP"
            cidr_blocks = ["MyIp"]
            sg_names    = null
          }
        }
      }

      # RDS管理サーバ用のセキュリティグループ
      sg_for_rdsmanageserver = {
        name        = "sg_for_rdsmanageserver"
        description = "Allow TCP Traffic of Internal-SSH"
        vpc_name    = "vpc_for_backuptest"

        rules_ingress = {
          allow_ssh = {
            from_port = 22
            to_port   = 22
            protocol  = "TCP"
            cidr_blocks = ["MyIp"]
            sg_names    = null
          }
        }
      }
    }

    child = {
      # WEB用のセキュリティグループ
      sg_for_webserver = {
        name        = "sg_for_webserver"
        description = "Allow TCP from LB-SecurityGroup and Internal-SSH"
        vpc_name    = "vpc_for_backuptest"

        rules_ingress = {
          allow_tcp = {
            from_port   = 5000
            to_port     = 5000
            protocol    = "TCP"
            cidr_blocks = null
            sg_names    = ["sg_for_lb"]
          }
          allow_ssh = {
            from_port = 22
            to_port   = 22
            protocol  = "TCP"
            cidr_blocks = ["MyIp"]
            sg_names    = null
          }
        }
      }

      
    }

    grandchild = {
      # RDSクラスター用のセキュリティグループ
      sg_for_rdscluster = {
        name        = "sg_for_rdscluster"
        description = "Allow TCP from SecurityGroup of Web/RDSManage Servers"
        vpc_name    = "vpc_for_backuptest"

        rules_ingress = {
          allow_mysql = {
            from_port   = 3306
            to_port     = 3306
            protocol    = "TCP"
            cidr_blocks = null
            sg_names    = ["sg_for_webserver", "sg_for_rdsmanageserver"]
          }
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
      Web-Server1 = {
        ami                         = "ami-02a2700d37baeef8b" # AL2
        availability_zone           = "ap-northeast-1a"
        instance_type               = "t2.micro"
        associate_public_ip_address = true
        subnet_name                 = "subnet_for_webserver1"
        security_group_names        = ["sg_for_webserver"]
        source_dest_check           = null
        key_name                    = "keypair-for-webapp"
        user_data                   = "app_setup_AL2.sh"
        role_name                   = null
      }
    }

    # RDS管理用インスタンス
    db = {
      rdsmanageserver = {
        ami                         = "ami-0cd0830ef4d2de449" # RHEL
        availability_zone           = "ap-northeast-1a"
        instance_type               = "t2.micro"
        associate_public_ip_address = true
        subnet_name                 = "subnet_for_rdsmanageserver"
        security_group_names        = ["sg_for_rdsmanageserver"]
        source_dest_check           = null
        key_name                    = "keypair-for-webapp"
        user_data                   = "db_setup_RHEL.sh"
        role_name                   = null
      }
    }
  }
}


# ルートテーブルのパラメータ
variable "rtb_params" {
  default = {
    # LBのインターネットゲートウェイ向きのトラフィック用
    rtb_for_lb1 = {
      name = "rtb_for_lb1"
      vpc_name    = "vpc_for_backuptest"
      subnet_name = "subnet_for_lb1"
      routes = {
        for_igw = {
          destination = "0.0.0.0/0"
          type_dst    = "gateway"
          next_hop    = "igw_for_lb"
        }
      }
    }

    # LBのインターネットゲートウェイ向きのトラフィック用
    rtb_for_lb2 = {
      name = "rtb_for_lb2"
      vpc_name    = "vpc_for_backuptest"
      subnet_name = "subnet_for_lb2"
      routes = {
        for_igw = {
          destination = "0.0.0.0/0"
          type_dst    = "gateway"
          next_hop    = "igw_for_lb"
        }
      }
    }

    # WEBサーバが必要なパッケージをinstallする時のアウトバウンド用
    rtb_for_webserver1 = {
      name = "rtb_for_webserver1"
      vpc_name    = "vpc_for_backuptest"
      subnet_name = "subnet_for_webserver1"
      routes = {
        for_igw = {
          destination = "0.0.0.0/0"
          type_dst    = "gateway"
          next_hop    = "igw_for_lb"
        }
      }
    }

    # RDS管理サーバが必要なパッケージをinstallする時のアウトバウンド用
    rtb_for_rdsmanageserver = {
      name = "rtb_for_rdsmanageserver"
      vpc_name    = "vpc_for_backuptest"
      subnet_name = "subnet_for_rdsmanageserver"
      routes = {
        for_igw = {
          destination = "0.0.0.0/0"
          type_dst    = "gateway"
          next_hop    = "igw_for_lb"
        }
      }
    }
  }
}


# ロードバランサーのパラメータ群
variable "lb_params" {
  default = {
    ALBBackupTest = {
      name               = "ALBBackupTest"
      internal           = false
      load_balancer_type = "application"
      subnet_names = [
        "subnet_for_lb1",
        "subnet_for_lb2",
      ]
      sg_names = ["sg_for_lb"]
    }
  }
}

variable "tg_params" {
  default = {
    TargetGroupALBBackupTest = {
      name        = "TargetGroupALBBackupTest"
      vpc_name    = "vpc_for_backuptest"
      target_type = "instance"
      port        = 5000
      protocol    = "HTTP"
      health_check = {
        path     = "/"
        port     = 5000
        protocol = "HTTP"
      }
    }
  }
}

variable "tg_attachment_params" {
  default = {
    webserver1_listen = {
      tg_name     = "TargetGroupALBBackupTest"
      target_type = "instance"
      target      = "Web-Server1"
      port        = 5000
    }
  }
}

variable "listener_params" {
  default = {
    listener_for_ALBBackupTest = {
      lb_name     = "ALBBackupTest"
      tg_name     = "TargetGroupALBBackupTest"
      port        = 80
      protocol    = "HTTP"
      action_type = "forward"
    }
  }
}