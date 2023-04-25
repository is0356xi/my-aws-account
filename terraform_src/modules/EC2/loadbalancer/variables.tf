# ロードバランサーのパラメータ群
variable "lb_params" {}
variable "tg_params" {}
variable "tg_attachment_params" {}
variable "listener_params" {}

# 作成済みのVPC・サブネット・EIP・セキュリティグループ・EC2
variable "created_vpc" {}
variable "created_subnet" {}
variable "created_eip" {}
variable "created_sg" {}
variable "created_ec2" {}



