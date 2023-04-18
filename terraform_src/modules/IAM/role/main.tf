data "aws_iam_policy" "managed_policy" {
  for_each = var.role_params

  # AWSマネージドのポリシーを取得。それ以外はダミーでEC2 ReadOnlyを取得
  name = each.value.policy_type == "managed" ? each.value.policy_name : "AmazonEC2ReadOnlyAccess"
}

# IAMロールを作成
resource "aws_iam_role" "role" {
  for_each = var.role_params

  name               = each.value.role_name
  assume_role_policy = file("../../../modules/IAM/role/policy/${each.value.assume_role_file}")

  managed_policy_arns = each.value.policy_type == "managed" ? [data.aws_iam_policy.managed_policy[each.value.role_name].arn] : null

  inline_policy {
    name   = each.value.policy_type == "managed" ? null : each.value.policy_name
    policy = each.value.policy_type == "managed" ? null : file("../../../modules/IAM/role/policy/${each.value.policy_name}")
  }
}