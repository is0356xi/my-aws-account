# terraform.tfvarsの変数を読み込み
# variable "xxx" {}

# 環境固有の変数
variable env_params {
    default = {
        tag = {
            env = "dev"
        }
    }
}

