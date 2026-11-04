output "vpc_id" {
  description = "ID de la VPC creada por el módulo."
  value       = aws_vpc.this.id
}

output "private_subnet_ids" {
  description = "Mapa de IDs de subredes privadas indexado por zona de disponibilidad."
  value = {
    for availability_zone, subnet in aws_subnet.private :
    availability_zone => subnet.id
  }
}

output "private_route_table_ids" {
  description = "Mapa de IDs de tablas de rutas privadas indexado por zona de disponibilidad."
  value = {
    for availability_zone, route_table in aws_route_table.private :
    availability_zone => route_table.id
  }
}

output "s3_vpc_endpoint_id" {
  description = "ID del Gateway VPC Endpoint de S3."
  value       = aws_vpc_endpoint.s3.id
}
