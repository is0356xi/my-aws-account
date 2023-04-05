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
    # FortigateVM起動用のVPC
    vpc_for_launch_FortigateVM = {
      cidr_block           = "10.0.0.0/16"
      enable_dns_hostnames = true
      enable_dns_support   = true
    }
  }
}

# インターネットゲートウェイのパラメータ
variable "igw_params" {
  default = {
    igw_for_FortigateVM = {
      vpc_name = "vpc_for_launch_FortigateVM"
    }
  }
}

# サブネットのパラメータ
variable "subnet_params" {
  default = {
    # Fortigate管理用のサブネット
    subnet_for_Fortigate_Management = {
      vpc_name          = "vpc_for_launch_FortigateVM"
      cidr_block        = "10.0.0.0/24"
      availability_zone = "ap-northeast-1a"
    }

    # Fortigateクライアント接続用のサブネット
    subnet_for_Fortigate_External = {
      vpc_name          = "vpc_for_launch_FortigateVM"
      cidr_block        = "10.0.1.0/24"
      availability_zone = "ap-northeast-1a"
    }

    # FortigateのHA用サブネット
    subnet_for_Fortigate_HA = {
      vpc_name          = "vpc_for_launch_FortigateVM"
      cidr_block        = "10.0.2.0/24"
      availability_zone = "ap-northeast-1a"
    }

    # FortigateのHA管理用サブネット
    subnet_for_HA_Management = {
      vpc_name          = "vpc_for_launch_FortigateVM"
      cidr_block        = "10.0.3.0/24"
      availability_zone = "ap-northeast-1a"
    }

    # FortigateのHA管理用サブネット(VPNテスト用のリソースを配置するサブネット)
    subnet_for_Fortigate_Internal = {
      vpc_name          = "vpc_for_launch_FortigateVM"
      cidr_block        = "10.0.10.0/24"
      availability_zone = "ap-northeast-1a"
    }

    # ロードバランサー配置用のサブネット
    subnet_for_lb = {
      vpc_name          = "vpc_for_launch_FortigateVM"
      cidr_block        = "10.0.50.0/24"
      availability_zone = "ap-northeast-1a"
    }


  }
}

# セキュリティグループのパラメータ
variable "sg_params" {
  default = {
    parent = {
      sg_for_fortigate_management = {
        name        = "sg_for_fortigate_management"
        description = "Allow Fortigate Management Traffic"
        vpc_name    = "vpc_for_launch_FortigateVM"

        rules_ingress = {
          allow_ssh = {
            from_port   = 22
            to_port     = 22
            protocol    = "TCP"
            cidr_blocks = ["MyIp"]
          }
          allow_http = {
            from_port   = 80
            to_port     = 80
            protocol    = "TCP"
            cidr_blocks = ["MyIp"]
          }
          allow_https = {
            from_port   = 443
            to_port     = 443
            protocol    = "TCP"
            cidr_blocks = ["MyIp"]
          }
          allow_fortitraffic_1 = {
            from_port   = 541
            to_port     = 541
            protocol    = "TCP"
            cidr_blocks = ["MyIp"]
          }
          allow_fortitraffic_2 = {
            from_port   = 3000
            to_port     = 3000
            protocol    = "TCP"
            cidr_blocks = ["MyIp"]
          }
          allow_fortitraffic_3 = {
            from_port   = 8080
            to_port     = 8080
            protocol    = "TCP"
            cidr_blocks = ["MyIp"]
          }
        }
      }

      sg_for_fortigate_external = {
        name        = "sg_for_fortigate_external"
        description = "Allow Fortigate External Traffic"
        vpc_name    = "vpc_for_launch_FortigateVM"

        rules_ingress = {
          allow_vpn = {
            from_port   = 4433
            to_port     = 4433
            protocol    = "TCP"
            cidr_blocks = ["0.0.0.0/0"]
          }
          allow_ping = {
            from_port   = 8
            to_port     = 0
            protocol    = "ICMP"
            cidr_blocks = ["0.0.0.0/0"]
          }
        }
      }

      sg_for_fortigate_vpn = {
        name        = "sg_for_fortigate_vpn"
        description = "Allow Fortigate vpn Traffic"
        vpc_name    = "vpc_for_launch_FortigateVM"

        rules_ingress = {
          allow_vpn_traffic = {
            from_port   = 0
            to_port     = 0
            protocol    = "ALL"
            cidr_blocks = ["10.212.0.0/16"]
          }
        }
      }
    }

    child = {}
  }
}

# EC2のパラメータ
variable "ec2_params" {
  default = {
    # FortigateVMのパラメータ
    FortigateVM = {
      ami                         = "ami-0f413df152d16824c"
      availability_zone           = "ap-northeast-1a"
      instance_type               = "c4.xlarge"
      associate_public_ip_address = true
      subnet_name                 = "subnet_for_Fortigate_Management"
      security_group_names        = ["sg_for_fortigate_management"]
      source_dest_check           = false # 送信元/送信先の変更チェックをオフに
      key_name                    = null
    }

    # FortigateVMのパラメータ
    FortigateVM2 = {
      ami                         = "ami-0f413df152d16824c"
      availability_zone           = "ap-northeast-1a"
      instance_type               = "c4.xlarge"
      associate_public_ip_address = true
      subnet_name                 = "subnet_for_Fortigate_Management"
      security_group_names        = ["sg_for_fortigate_management"]
      source_dest_check           = false # 送信元/送信先の変更チェックをオフに
      key_name                    = null
    }

    # VPNテスト用インスタンス
    TestVM = {
      ami                         = "ami-02a2700d37baeef8b"
      availability_zone           = "ap-northeast-1a"
      instance_type               = "t2.micro"
      associate_public_ip_address = false
      subnet_name                 = "subnet_for_Fortigate_Internal"
      security_group_names        = ["sg_for_fortigate_vpn"]
      source_dest_check           = true
      key_name                    = null
    }
  }
}

# ENI・ElasticIPのパラメータ
variable "eni_params" {
  default = {
    ## FortigateVMにアタッチするENI群
    # クライアント接続用ポート
    eni_for_FortigateVM_Port2 = {
      subnet_name          = "subnet_for_Fortigate_External"
      security_group_names = ["sg_for_fortigate_external"]
      ec2_name             = "FortigateVM"
      device_index         = 1
      private_ips          = ["10.0.1.11"]
      source_dest_check    = false # 送信元/送信先の変更チェックをオフに
    }
    # 内部(VPC側)接続用ポート
    eni_for_FortigateVM_Port3 = {
      subnet_name          = "subnet_for_Fortigate_Internal"
      security_group_names = ["sg_for_fortigate_vpn"]
      ec2_name             = "FortigateVM"
      device_index         = 2
      private_ips          = ["10.0.10.100"]
      source_dest_check    = false # 送信元/送信先の変更チェックをオフに
    }
    # HA用ポート
    eni_for_FortigateVM_Port4 = {
      subnet_name          = "subnet_for_Fortigate_HA"
      security_group_names = ["sg_for_fortigate_management"]
      ec2_name             = "FortigateVM"
      device_index         = 3
      private_ips          = ["10.0.2.11"]
      source_dest_check    = false # 送信元/送信先の変更チェックをオフに
    }

    ## FortigateVM2にアタッチするENI群
    # クライアント接続用ポート
    eni2_for_FortigateVM_Port2 = {
      subnet_name          = "subnet_for_Fortigate_External"
      security_group_names = ["sg_for_fortigate_external"]
      ec2_name             = "FortigateVM2"
      device_index         = 1
      private_ips          = ["10.0.1.22"]
      source_dest_check    = false # 送信元/送信先の変更チェックをオフに
    }
    # 内部(VPC側)接続用ポート
    eni2_for_FortigateVM_Port3 = {
      subnet_name          = "subnet_for_Fortigate_Internal"
      security_group_names = ["sg_for_fortigate_vpn"]
      ec2_name             = "FortigateVM2"
      device_index         = 2
      private_ips          = ["10.0.10.200"]
      source_dest_check    = false # 送信元/送信先の変更チェックをオフに
    }
    # HA用ポート
    eni2_for_FortigateVM_Port4 = {
      subnet_name          = "subnet_for_Fortigate_HA"
      security_group_names = ["sg_for_fortigate_management"]
      ec2_name             = "FortigateVM2"
      device_index         = 3
      private_ips          = ["10.0.2.22"]
      source_dest_check    = false # 送信元/送信先の変更チェックをオフに
    }
  }
}

variable "eip_params" {
  default = {
    # AZ②FortigateVMにアタッチするEIP (クライアント接続用ポート)
    eip_for_FortigateVM_Port2 = {
      eni_name        = "eni_for_FortigateVM_Port2"
      public_address  = "amazon"
      private_address = null
    }

    # AZ②FortigateVMにアタッチするEIP (クライアント接続用ポート)
    eip2_for_FortigateVM_Port2 = {
      eni_name        = "eni2_for_FortigateVM_Port2"
      public_address  = "amazon"
      private_address = null
    }
  }
}

# ルートテーブルのパラメータ
variable "rtb_params" {
  default = {
    # Fortigate管理用サブネットのルートテーブル
    rtb_for_Fortigate_Management = {
      name = "rtb_for_Fortigate_Management"

      # アタッチするネットワークの情報
      vpc_name    = "vpc_for_launch_FortigateVM"
      subnet_name = "subnet_for_Fortigate_Management"

      # ルート定義
      routes = {
        toward_igw = {
          destination = "0.0.0.0/0"
          type_dst    = "gateway"
          next_hop    = "igw_for_FortigateVM"
        }
      }
    }

    # Fortigateクライアント接続用サブネットのルートテーブル
    rtb_for_Fortigate_External = {
      name = "rtb_for_Fortigate_External"

      # アタッチするネットワークの情報
      vpc_name    = "vpc_for_launch_FortigateVM"
      subnet_name = "subnet_for_Fortigate_External"

      # ルート定義
      routes = {
        toward_igw = {
          destination = "0.0.0.0/0"
          type_dst    = "gateway"
          next_hop    = "igw_for_FortigateVM"
        }
      }
    }

    # VPNテスト用のルートテーブル
    rtb_for_vpn_traffic = {
      name = "rtb_for_vpn_traffic"

      # アタッチするネットワークの情報
      vpc_name    = "vpc_for_launch_FortigateVM"
      subnet_name = "subnet_for_Fortigate_Internal"

      # ルート定義
      routes = {
        toward_fortigate_gateway = {
          destination = "10.212.133.0/24"
          type_dst    = "network_interface"
          next_hop    = "eni_for_FortigateVM_Port3"
        }
        toward_fortigate_2 = {
          destination = "10.212.134.0/24"
          type_dst    = "network_interface"
          next_hop    = "eni2_for_FortigateVM_Port3"
        }
      }
    }

    # ロードバランサー用のルート
    rtb_for_lb = {
      name = "rtb_for_lb"

      # アタッチするネットワークの情報
      vpc_name    = "vpc_for_launch_FortigateVM"
      subnet_name = "subnet_for_lb"

      # ルート定義
      routes = {
        toward_igw = {
          destination = "0.0.0.0/0"
          type_dst    = "gateway"
          next_hop    = "igw_for_FortigateVM"
        }
      }
    }
  }
}


# ロードバランサーのパラメータ群
variable "lb_params" {
  default = {
    NLBFortigate = {
      name               = "NLBFortigate"
      internal           = false
      load_balancer_type = "network"
      subnet_names = [
        "subnet_for_lb",
      ]
    }
  }
}

variable "tg_params" {
  default = {
    TargetGroupFortigateNLB = {
      name        = "TargetGroupFortigateNLB"
      vpc_name    = "vpc_for_launch_FortigateVM"
      target_type = "ip"
      port        = 4433
      protocol    = "TCP"
      health_check = {
        path     = "/"
        port     = 4433
        protocol = "TCP"
      }
    }
  }
}

variable "tg_attachment_params" {
  default = {
    ip_fortigate_vpnlisten = {
      tg_name     = "TargetGroupFortigateNLB"
      target_type = "ip"
      target      = "eip_for_FortigateVM_Port2"
      port        = 4433
    }
    ip2_fortigate_vpnlisten = {
      tg_name     = "TargetGroupFortigateNLB"
      target_type = "ip"
      target      = "eip2_for_FortigateVM_Port2"
      port        = 4433
    }
  }
}

variable "listener_params" {
  default = {
    listener_for_FortigateNLB = {
      lb_name     = "NLBFortigate"
      tg_name     = "TargetGroupFortigateNLB"
      port        = 4433
      protocol    = "TCP"
      action_type = "forward"
    }
  }
}
