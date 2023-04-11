resource "aws_iam_instance_profile" "ip" {
  for_each = var.ec2_params

  name = each.value.role_name == null ? null : each.value.role_name
  role = each.value.role_name == null ? null : var.created_role[each.value.role_name].name
}

resource "aws_instance" "instance" {
  for_each = var.ec2_params

  ami                         = each.value.ami
  availability_zone           = each.value.availability_zone
  instance_type               = each.value.instance_type
  associate_public_ip_address = each.value.associate_public_ip_address
  source_dest_check           = each.value.source_dest_check
  key_name                    = each.value.key_name
  subnet_id                   = var.created_subnet[each.value.subnet_name].id

  # ユーザデータ
  user_data = each.value.user_data == null ? null : templatefile(
    each.value.user_data,
    {
      vars = var.user_data_vars[each.key]
    }
  )

  # セキュリティグループのアタッチ
  vpc_security_group_ids = [
    for sg_name in each.value.security_group_names : var.created_sg[sg_name].id
  ]

  # IAMインスタンスプロファイルのアタッチ
  iam_instance_profile = aws_iam_instance_profile.ip[each.key].name

  tags = {
    Name = each.key
  }

  depends_on = [
    aws_iam_instance_profile.ip
  ]
}
