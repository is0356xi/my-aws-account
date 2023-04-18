# mediaconnect VPCインタフェースのパラメータ
variable "mc_vpcif_params" {}

# 作成済みのセキュリティグループ・サブネット・IAMロール
variable "created_sg" {}
variable "created_subnet" {}
variable "created_role" {}

# 作成済みのFlowArn(terraform.tfvarsで定義)
variable "flow_arn" {}