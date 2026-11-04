variable "state_bucket_name" {
  description = "Nombre globalmente unico del bucket S3 para el estado remoto."
  type        = string
}

variable "aws_region" {
  description = "Region de AWS."
  type        = string
  default     = "us-east-1"
}

