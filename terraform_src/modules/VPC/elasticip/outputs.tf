output "created_eni" {
  value = aws_network_interface.eni
}

output "created_eip" {
  value = aws_eip.eip
}