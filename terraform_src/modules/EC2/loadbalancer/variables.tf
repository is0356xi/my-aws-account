# ロードバランサーのパラメータ群
variable "lb_params" {}
variable "tg_params" {}
variable "tg_attachment_params" {}
variable "listener_params" {}

# 作成済みのVPC・サブネット・EIP
variable "created_vpc" {}
variable "created_subnet" {}
variable "created_eip" {}



