resource "aws_lb" "lb" {
  for_each = var.lb_params

  name               = each.value.name
  internal           = each.value.internal
  load_balancer_type = each.value.load_balancer_type
  subnets            = [for name in each.value.subnet_names : var.created_subnet[name].id]
  security_groups = each.value.load_balancer_type == "application" ? [for name in each.value.sg_names: var.created_sg[name].id] : null
  
  tags = {
    Name = each.key
  }
}

resource "aws_lb_target_group" "tg" {
  for_each = var.tg_params

  name        = each.value.name
  target_type = each.value.target_type
  port        = each.value.port
  protocol    = each.value.protocol

  health_check {
    port     = each.value.health_check.port
    protocol = each.value.health_check.protocol
    path     = each.value.health_check.path
    matcher  = each.value.health_check.protocol == "TCP" ? null : null
  }

  vpc_id = var.created_vpc[each.value.vpc_name].id
}

resource "aws_lb_target_group_attachment" "tg_attachment" {
  for_each = var.tg_attachment_params

  target_group_arn = aws_lb_target_group.tg[each.value.tg_name].arn

  target_id        = each.value.target_type == "ip" ? var.created_eip[each.value.target].private_ip : each.value.target_type == "instance" ? var.created_ec2[each.value.target].id : null
  port             = each.value.port

  depends_on = [aws_lb_target_group.tg]
}

resource "aws_lb_listener" "listener" {
  for_each = var.listener_params

  load_balancer_arn = aws_lb.lb[each.value.lb_name].arn
  port              = each.value.port
  protocol          = each.value.protocol

  default_action {
    type             = each.value.action_type
    target_group_arn = aws_lb_target_group.tg[each.value.tg_name].arn
  }

  depends_on = [aws_lb.lb, aws_lb_target_group.tg]
}
