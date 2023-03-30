# AzureADのグループ・ユーザを作成する
module "create_azuread_identity" {
  source = "../../../modules/AzureAD"

  group_params = var.group_params
  user_params  = var.user_params
}