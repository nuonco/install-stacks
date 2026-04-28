output "vpc_id" {
  value = aws_vpc.main.id
}

output "vpc_cidr" {
  value = aws_vpc.main.cidr_block
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "private_subnet_id" {
  value = aws_subnet.private.id
}

output "runner_subnet_id" {
  value = aws_subnet.runner.id
}

output "runner_security_group_id" {
  value = aws_security_group.runner.id
}

output "nat_gateway_id" {
  value = aws_nat_gateway.main.id
}

output "internet_gateway_id" {
  value = aws_internet_gateway.main.id
}
