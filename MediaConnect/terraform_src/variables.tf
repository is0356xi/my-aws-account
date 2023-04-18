# tfvarsの変数を受け取る
variable "profile_name" {}
variable "flow_arn" {}

# VPCのパラメータ
variable "vpc_params" {
  default = {
    vpc_for_mediaconnect = {
      cidr_block           = "10.0.0.0/22"
      enable_dns_support   = true
      enable_dns_hostnames = true
    }
  }
}

# サブネットのパラメータ
variable "subnet_params" {
  default = {
    subnet_vpc_interface = {
      cidr_block        = "10.0.0.0/24"
      availability_zone = "ap-northeast-1a"
      vpc_name          = "vpc_for_mediaconnect"
    }
  }
}

# mediaconnect用のセキュリティグループのパラメータ
variable "sg_params" {
  default = {
    sg_for_mediaconnect = {
      name        = "sg_for_mediaconnect"
      description = "allow all traffic from directconnect"
      vpc_name    = "vpc_for_mediaconnect"

      rules_ingress = {
        allow_tcp = {
          from_port   = 0
          to_port     = 0
          protocol    = "ALL"
          cidr_blocks = ["172.31.16.0/24"]
        }
      }
    }
  }
}

# IAMロールのパラメータ
variable "role_params" {
  default = {
    role_for_vpcif_mediaconnect = {
      role_name        = "role_for_vpcif_mediaconnect"
      assume_role_file = "assumerole_for_mediaconnect.json"
      policy_type      = "file" # managed or file
      policy_name      = "inlinepolicy_for_create_ENI.json"
    }
  }
}


# mediaconnect VPCインタフェースのパラメータ
variable "mc_vpcif_params" {
  default = {
    vpcif = {
      name        = "vpcif"
      role_name   = "role_for_vpcif_mediaconnect"
      subnet_name = "subnet_vpc_interface"
      sg_names    = ["sg_for_mediaconnect"]
    }
  }
}