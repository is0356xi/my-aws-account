resource "aws_network_interface" "eni" {
  for_each = var.eni_params

  subnet_id       = var.created_subnet[each.value.subnet_name].id
  security_groups = [for sg_name in each.value.security_group_names : var.created_sg[sg_name].id]

  attachment {
    instance     = var.created_ec2[each.value.ec2_name].id
    device_index = each.value.device_index
  }

  private_ips       = each.value.private_ips != null ? each.value.private_ips : null
  source_dest_check = each.value.source_dest_check
}

resource "aws_eip" "eip" {
  for_each = var.eip_params

  network_interface         = aws_network_interface.eni[each.value.eni_name].id
  public_ipv4_pool          = each.value.public_address != null ? each.value.public_address : null
  associate_with_private_ip = each.value.private_address != null ? each.value.private_address : null
}

