resource "aws_instance" "instance" {
  for_each = var.ec2_params

  ami                         = each.value.ami
  availability_zone           = each.value.availability_zone
  instance_type               = each.value.instance_type
  associate_public_ip_address = each.value.associate_public_ip_address
  source_dest_check           = each.value.source_dest_check
  key_name                    = each.value.key_name
  subnet_id                   = var.created_subnet[each.value.subnet_name].id

  vpc_security_group_ids = [
    for sg_name in each.value.security_group_names : var.created_sg[sg_name].id
  ]

  tags = {
    Name = each.key
  }
}
