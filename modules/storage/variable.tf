variable "environment" {
  description = "Nombre del entorno. Este stack está diseñado para dev."
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "coderhouse"
}