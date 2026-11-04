
locals {
  name_prefix = "${var.project_name}-${var.environment}"
  subnet_cidrs = {
    for index, availability_zone in var.availability_zones :
    availability_zone => cidrsubnet(var.vpc_cidr, 4, index)
  }
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "private" {
  for_each = local.subnet_cidrs

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.key
  cidr_block              = each.value
  map_public_ip_on_launch = false

}

resource "aws_route_table" "private" {
  for_each = local.subnet_cidrs

  vpc_id = aws_vpc.this.id

}

resource "aws_route_table_association" "private" {
  for_each = local.subnet_cidrs

  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [for route_table in aws_route_table.private : route_table.id]
}
