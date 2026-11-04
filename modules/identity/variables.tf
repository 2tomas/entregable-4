variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "coderhouse"
}

variable "environment" {
  description = "Nombre del ambiente"
  type        = string
}
variable "data_bucket_arn" {
  description = "Nombre del arn del bucket s3"
  type        = string
}

variable "data_prefix" {
  description = "prefijo del bucket S3"
  type        = string

}

variable "audit_principal_arns" {
  description = "ARNs de roles o usuarios autorizados a asumir el rol de auditoría."
  type        = list(string)
}
