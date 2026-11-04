variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "coderhouse"
}

variable "environment" {
  description = "Nombre del ambiente"
  type        = string

}

variable "availability_zones" {
  description = "Lista de las zonas"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]

  validation {
    condition = (
      length(var.availability_zones) >= 2 &&
      length(distinct(var.availability_zones)) == length(var.availability_zones)
    )
    error_message = "availability_zones debe contener al menos dos zonas de disponibilidad diferentes."
  }
}
variable "vpc_cidr" {
  description = "Bloque CIDR IPv4 de la VPC"
  type        = string
}

variable "aws_region" {
  description = "Nombre de la region"
  type        = string
  default     = "us-east-1"
}

