output "vpc_id" {
  description = "ID da VPC"
  value       = aws_vpc.SREMack.id
}

output "public_subnet_id" {
  description = "ID da Subnet Pública"
  value       = aws_subnet.SREpublic_subnet.id
}

output "private_subnet_id" {
  description = "ID da Subnet Privada"
  value       = aws_subnet.SREprivate_subnet.id
}

output "internet_gateway_id" {
  description = "ID do Internet Gateway"
  value       = aws_internet_gateway.SREMack.id
}

output "rds_instance_id" {
  description = "ID da instância RDS"
  value       = aws_db_instance.SREMack.id
}
