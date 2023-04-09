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
      # VPCエンドポイント用のセキュリティグループ
      sg_for_vpcendpoint = {
        name        = "sg_for_vpcendpoint"
        description = "Allow ALL Traffic from AWS-Service"
        vpc_name    = "vpc_for_securitytest"

        rules_ingress = {
          allow_icmp = {
            from_port   = 443
            to_port     = 443
            protocol    = "TCP"
            cidr_blocks = ["0.0.0.0/0"]
            sg_names    = null
          }
        }
      }
    }

    child = {
      # 開発サーバ用のセキュリティグループ
      sg_for_devserver = {
        name        = "sg_for_devserver"
        description = "Allow ALL Traffic from VPC-endpoint"
        vpc_name    = "vpc_for_securitytest"

        rules_ingress = {
          allow_icmp = {
            from_port   = -1
            to_port     = -1
            protocol    = "ICMP"
            cidr_blocks = ["MyIp"]
            sg_names    = null
          }
          allow_https = {
            from_port   = 443
            to_port     = 443
            protocol    = "TCP"
            cidr_blocks = null
            sg_names    = ["sg_for_vpcendpoint"]
          }
        }
      }
    }

    grandchild = {
      # Webサーバ用のセキュリティグループ
      sg_for_webserver = {
        name        = "sg_for_webserver"
        description = "Allow HTTP and Internal-SSH"
        vpc_name    = "vpc_for_securitytest"

        rules_ingress = {
          allow_ssh = {
            from_port   = 22
            to_port     = 22
            protocol    = "TCP"
            cidr_blocks = null
            sg_names    = ["sg_for_devserver"]
          }
          allow_http = {
            from_port   = 80
            to_port     = 80
            protocol    = "TCP"
            cidr_blocks = ["MyIp"]
            sg_names    = null
          }
        }
      }
    }

    great_grandchild = {
      # DBサーバ用のセキュリティグループ
      sg_for_dbserver = {
        name        = "sg_for_dbserver"
        description = "Allow Internal-API and Internal-SSH"
        vpc_name    = "vpc_for_securitytest"

        rules_ingress = {
          allow_ssh = {
            from_port   = 22
            to_port     = 22
            protocol    = "TCP"
            cidr_blocks = null
            sg_names    = ["sg_for_devserver"]
          }
          allow_dbapi = {
            from_port   = 8080
            to_port     = 8080
            protocol    = "TCP"
            cidr_blocks = null
            sg_names    = ["sg_for_webserver"]
          }
        }
      }
    }
  }
}

# EC2のパラメータ
variable "ec2_params" {
  default = {
    Web-Server = {
      ami                         = "ami-02a2700d37baeef8b"
      availability_zone           = "ap-northeast-1a"
      instance_type               = "t2.micro"
      associate_public_ip_address = false
      subnet_name                 = "publicsubnet_for_webserver"
      security_group_names        = ["sg_for_webserver"]
      source_dest_check           = null
      key_name                    = "keypair-for-SecurityTest"
    }

    DB-Server = {
      ami                         = "ami-02a2700d37baeef8b"
      availability_zone           = "ap-northeast-1a"
      instance_type               = "t2.micro"
      associate_public_ip_address = false
      subnet_name                 = "privatesubnet_for_dbserver"
      security_group_names        = ["sg_for_dbserver"]
      source_dest_check           = null
      key_name                    = "keypair-for-SecurityTest"
    }

    Dev-Server = {
      ami                         = "ami-02a2700d37baeef8b"
      availability_zone           = "ap-northeast-1a"
      instance_type               = "t2.micro"
      associate_public_ip_address = false
      subnet_name                 = "privatesubnet_for_devserver"
      security_group_names        = ["sg_for_devserver"]
      source_dest_check           = null
      key_name                    = "keypair-for-SecurityTest"
    }
  }
}

# ENI・ElasticIPのパラメータ
variable "eni_params" {
  default = {
    # アタッチするENI群
    eni_for_webserver = {
      subnet_name          = "publicsubnet_for_webserver"
      security_group_names = ["sg_for_webserver"]
      ec2_name             = "Web-Server"
      device_index         = 1
      private_ips          = null
      source_dest_check    = null
    }
  }
}

variable "eip_params" {
  default = {
    # FortigateVMにアタッチするEIP 
    eip_for_webserver = {
      eni_name        = "eni_for_webserver"
      public_address  = "amazon"
      private_address = null
    }
  }
}

# ルートテーブルのパラメータ
variable "rtb_params" {
  default = {
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
  }
}