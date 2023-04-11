# 環境固有の変数
variable "env_params" {}

# EC2インスタンスのパラメータ
variable "ec2_params" {}

# 作成済みのサブネット・セキュリティグループ・IAMロール
variable "created_subnet" {}
variable "created_sg" {}
variable "created_role" {}

# ユーザデータに注入する変数
variable "user_data_vars" {}


