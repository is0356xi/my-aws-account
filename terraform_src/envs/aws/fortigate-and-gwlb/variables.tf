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
    vpc_for_Inspection = {
      cidr_block           = "10.0.0.0/16"
      enable_dns_hostnames = true
      enable_dns_support   = true
    }

    # 外部アクセス用のVPC
    vpc_for_ExternalAccess = {
      cidr_block           = "10.1.0.0/16"
      enable_dns_hostnames = true
      enable_dns_support   = true
    }
  }
}

# インターネットゲートウェイのパラメータ
variable "igw_params" {
  default = {
    # Fortigateの管理用
    igw_for_Fortigate_Management = {
      vpc_name = "vpc_for_Inspection"
    }

    # クライアントの外部接続用
    igw_for_ExternalAccess = {
      vpc_name = "vpc_for_ExternalAccess"
    }
  }
}

# サブネットのパラメータ
variable "subnet_params" {
  default = {
    # トラフィック検査用VPC内のサブネット (Fortigateの管理用ENIを配置するサブネット)
    subnet_for_GWLB_create = {
      vpc_name          = "vpc_for_Inspection"
      cidr_block        = "10.0.100.0/24"
      availability_zone = "ap-northeast-1a"
    }

    # トラフィック検査用VPC内のサブネット (Fortigateの管理用ENIを配置するサブネット)
    subnet_for_Fortigate_Management = {
      vpc_name          = "vpc_for_Inspection"
      cidr_block        = "10.0.0.0/24"
      availability_zone = "ap-northeast-1a"
    }

    # トラフィック検査用VPC内のサブネット (GWLBeと接続するENIを配置するサブネット)
    subnet_for_Inspection = {
      vpc_name          = "vpc_for_Inspection"
      cidr_block        = "10.0.1.0/24"
      availability_zone = "ap-northeast-1a"
    }

    # GWLB用エンドポイントのサブネット
    subnet_for_GWLBe = {
      vpc_name          = "vpc_for_ExternalAccess"
      cidr_block        = "10.1.0.0/28"
      availability_zone = "ap-northeast-1a"
    }

    # テスト用VMを配置するサブネット
    subnet_for_TestEC2 = {
      vpc_name          = "vpc_for_ExternalAccess"
      cidr_block        = "10.1.5.0/24"
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
        vpc_name    = "vpc_for_Inspection"

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
        vpc_name    = "vpc_for_Inspection"

        rules_ingress = {
          allow_icmp = {
            from_port   = -1
            to_port     = -1
            protocol    = "ICMP"
            cidr_blocks = ["0.0.0.0/0"]
          }
          allow_https = {
            from_port   = 443
            to_port     = 443
            protocol    = "TCP"
            cidr_blocks = ["0.0.0.0/0"]
          }
        }
      }

      sg_for_TestEC2 = {
        name        = "sg_for_TestEC2"
        description = "Allow Fortigate vpn Traffic"
        vpc_name    = "vpc_for_ExternalAccess"

        rules_ingress = {
          allow_session_manager = {
            from_port   = 443
            to_port     = 443
            protocol    = "TCP"
            cidr_blocks = ["0.0.0.0/0"]
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
      instance_type               = "c4.large"
      associate_public_ip_address = true
      subnet_name                 = "subnet_for_Fortigate_Management"
      security_group_names        = ["sg_for_fortigate_management"]
      source_dest_check           = false # 送信元/送信先の変更チェックをオフに
      key_name                    = "keypair-for-FortigateVM"
    }

    # テスト用インスタンス
    TestVM = {
      ami                         = "ami-02a2700d37baeef8b"
      availability_zone           = "ap-northeast-1a"
      instance_type               = "t2.micro"
      associate_public_ip_address = false
      subnet_name                 = "subnet_for_TestEC2"
      security_group_names        = ["sg_for_TestEC2"]
      source_dest_check           = true
      key_name                    = null
    }
  }
}

# ENI・ElasticIPのパラメータ
variable "eni_params" {
  default = {
    # FortigateVMにアタッチするENI群
    eni_for_FortigateVM_Port2 = {
      subnet_name          = "subnet_for_Inspection"
      security_group_names = ["sg_for_fortigate_external"]
      ec2_name             = "FortigateVM"
      device_index         = 1
      private_ips          = null
      source_dest_check    = false # 送信元/送信先の変更チェックをオフに
    }
    eni_for_FortigateVM_Port3 = {
      subnet_name          = "subnet_for_Inspection"
      security_group_names = ["sg_for_fortigate_external"]
      ec2_name             = "FortigateVM"
      device_index         = 2
      private_ips          = ["10.0.1.200"]
      source_dest_check    = false # 送信元/送信先の変更チェックをオフに
    }
  }
}

variable "eip_params" {
  default = {
    # FortigateVMにアタッチするEIP 
    eip_for_FortigateVM_Port2 = {
      eni_name        = "eni_for_FortigateVM_Port2"
      public_address  = "amazon"
      private_address = null
    }
  }
}

# ルートテーブルのパラメータ
variable "rtb_params" {
  default = {
    # Fortigate管理用サブネットにアタッチするルートテーブル
    rtb_for_Fortigate_Management = {
      name = "rtb_for_Fortigate_Management"

      # アタッチするネットワークの情報
      vpc_name    = "vpc_for_Inspection"
      subnet_name = "subnet_for_Fortigate_Management"

      # ルート定義
      routes = {
        for_igw = {
          destination = "0.0.0.0/0"
          type_dst    = "gateway"
          next_hop    = "igw_for_Fortigate_Management"
        }
      }
    }

    # トラフィック検査用サブネットのルートテーブル
    rtb_for_Inspection = {
      name = "rtb_for_Inspection"

      # アタッチするネットワークの情報
      vpc_name    = "vpc_for_Inspection"
      subnet_name = "subnet_for_Inspection"

      # ルート定義　
      routes = {}
    }

    # テスト用インスタンスにアタッチするルートテーブル
    rtb_for_TestEC2 = {
      name = "rtb_for_TestEC2"

      # アタッチするネットワークの情報
      vpc_name    = "vpc_for_ExternalAccess"
      subnet_name = "subnet_for_TestEC2"

      # ルート定義
      routes = {} # (GWLBeに向けるルートにする)
    }

    # GWLBエンドポイントを配置するサブネットにアタッチするルートテーブル
    rtb_for_GWLBe = {
      name = "rtb_for_GWLBe"

      # アタッチするネットワークの情報
      vpc_name    = "vpc_for_ExternalAccess"
      subnet_name = "subnet_for_GWLBe"

      # ルート定義
      routes = {
        for_igw = {
          destination = "0.0.0.0/0"
          type_dst    = "gateway"
          next_hop    = "igw_for_ExternalAccess"
        }
      }
    }
  }
}


# VPCエンドポイントのパラメータ
variable "vpc_endpoint_params" {
  default = {
    ec2_messages = {
      service_name      = "com.amazonaws.ap-northeast-1.ec2messages"
      vpc_endpoint_type = "Interface"

      vpc_name             = "vpc_for_ExternalAccess"
      subnet_names         = ["subnet_for_TestEC2"]
      security_group_names = ["sg_for_TestEC2"]
      private_dns_enabled  = true
    }

    ssm = {
      service_name      = "com.amazonaws.ap-northeast-1.ssm"
      vpc_endpoint_type = "Interface"

      vpc_name             = "vpc_for_ExternalAccess"
      subnet_names         = ["subnet_for_TestEC2"]
      security_group_names = ["sg_for_TestEC2"]
      private_dns_enabled  = true
    }

    ssm_messages = {
      service_name      = "com.amazonaws.ap-northeast-1.ssmmessages"
      vpc_endpoint_type = "Interface"

      vpc_name             = "vpc_for_ExternalAccess"
      subnet_names         = ["subnet_for_TestEC2"]
      security_group_names = ["sg_for_TestEC2"]
      private_dns_enabled  = true
    }
  }
}