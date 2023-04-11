# VPCエンドポイントの作成
resource "aws_vpc_endpoint" "endpoint" {
  for_each = var.vpc_endpoint_params

  vpc_id            = var.created_vpc[each.value.vpc_name].id
  service_name      = each.value.service_name
  vpc_endpoint_type = each.value.vpc_endpoint_type

  subnet_ids = each.value.vpc_endpoint_type != "Interface" ? null : [
    for name in each.value.subnet_names : var.created_subnet[name].id
  ]

  security_group_ids = each.value.vpc_endpoint_type != "Interface" ? null :  [
    for name in each.value.security_group_names : var.created_sg[name].id
  ]

  route_table_ids = each.value.vpc_endpoint_type != "Gateway" ? null : [
    for name in each.value.rtb_names : var.created_rtb[name].id
  ]

  private_dns_enabled = each.value.private_dns_enabled
}