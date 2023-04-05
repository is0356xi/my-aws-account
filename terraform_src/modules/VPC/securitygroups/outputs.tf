output "created_sg" {
  value = merge(aws_security_group.sg, aws_security_group.child_sg)
}