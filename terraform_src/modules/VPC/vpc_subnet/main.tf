resource "aws_vpc" "vpc" {
  for_each = var.vpc_params

  cidr_block           = each.value.cidr_block
  enable_dns_hostnames = each.value.enable_dns_hostnames
  enable_dns_support   = each.value.enable_dns_support

  tags = {
    Name = each.key
  }

}

resource "aws_subnet" "subnet" {
  for_each = var.subnet_params

  vpc_id            = aws_vpc.vpc[each.value.vpc_name].id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = {
    Name = each.key
  }
}
