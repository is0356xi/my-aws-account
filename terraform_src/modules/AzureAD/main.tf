# Azure ADグループを作成
resource "azuread_group" "group" {
  for_each = var.group_params

  display_name     = each.value.display_name
  security_enabled = each.value.security_enabled
}

# Azure ADユーザを作成
resource "azuread_user" "user" {
  for_each = var.user_params

  user_principal_name   = each.value.user_principal_name
  display_name          = each.value.display_name
  password              = each.value.password
  force_password_change = true
}

# ユーザをグループに追加
resource "azuread_group_member" "member" {
  for_each = var.user_params

  group_object_id  = azuread_group.group[each.value.group_name].id
  member_object_id = azuread_user.user[each.value.display_name].id
}

# data "azurerm_role_definition" "role" {
#   for_each = var.avd_group_params
#   name     = each.value.role
# }

# グループにRBACロールを付与
# resource "azurerm_role_assignment" "role" {
#   for_each = var.avd_group_params

#   scope              = var.created_dag[each.value.dag_name].id
#   role_definition_id = data.azurerm_role_definition.role[each.key].id
#   principal_id       = azuread_group.group[each.value.name].id
# }



