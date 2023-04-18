# VPCインタフェースを作成
resource "awscc_mediaconnect_flow_vpc_interface" "vpcif" {
  for_each = var.mc_vpcif_params

  name               = each.value.name
  flow_arn           = var.flow_arn
  role_arn           = var.created_role[each.value.role_name].arn
  security_group_ids = [for obj in var.created_sg : obj.id]
  subnet_id          = var.created_subnet[each.value.subnet_name].id
}