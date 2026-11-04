variable "environment" {
  description = "Nombre del ambiente"
  type        = string
}

variable "data_bucket_arn" {
  description = "ARN del bucket S3 existente del Data Lake"
  type        = string
}
