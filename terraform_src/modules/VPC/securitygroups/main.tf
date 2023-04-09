# 親セキュリティグループの作成
resource "aws_security_group" "sg" {
  for_each = var.sg_params

  name        = each.value.name
  description = each.value.description
  vpc_id      = var.created_vpc[each.value.vpc_name].id

  dynamic "ingress" {
    for_each = each.value.rules_ingress
    content {
      description     = ingress.key
      from_port       = ingress.value.from_port
      to_port         = ingress.value.to_port
      protocol        = ingress.value.protocol
      cidr_blocks     = ingress.value.cidr_blocks == ["MyIp"] ? var.MyIp : ingress.value.cidr_blocks
      security_groups = ingress.value.sg_names == null ? null : [for name in ingress.value.sg_names : var.created_sg[name].id]
    }
  }

  # アウトバウンドは全てのトラフィックを許可
  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}