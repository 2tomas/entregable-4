variable "project_name" {
  description = "Nombre del proyecto."
  type        = string
  default     = "coderhouse"
}

variable "environment" {
  description = "Nombre del ambiente."
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "Region de AWS para todos los recursos."
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "Bloque CIDR IPv4 de la VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "availability_zones" {
  description = "Dos o mas zonas distintas de la region."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]

  validation {
    condition = (
      length(var.availability_zones) >= 2 &&
      length(distinct(var.availability_zones)) == length(var.availability_zones)
    )
    error_message = "availability_zones debe contener al menos dos zonas diferentes."
  }
}

variable "data_prefix" {
  description = "Prefijo S3 reservado para procesamiento."
  type        = string
  default     = "processing"
}

variable "audit_principal_arns" {
  description = "Roles o usuarios autorizados a asumir el rol de auditoria."
  type        = list(string)
}

variable "flink_jar_path" {
  description = "Ruta al fat JAR, relativa a environments/dev."
  type        = string
  default     = "../../application/target/realtime-metrics-flink-1.0.0.jar"
}

variable "runtime_environment" {
  description = "Runtime de Amazon Managed Service for Apache Flink."
  type        = string
  default     = "FLINK-1_20"

  validation {
    condition     = var.runtime_environment == "FLINK-1_20"
    error_message = "La aplicacion fue compilada para FLINK-1_20."
  }
}

variable "start_application" {
  description = "Inicia la aplicacion durante terraform apply. Genera consumo de KPUs."
  type        = bool
  default     = false
}

variable "checkpoint_interval_ms" {
  description = "Intervalo de checkpoints en milisegundos."
  type        = number
  default     = 60000

  validation {
    condition     = var.checkpoint_interval_ms >= 1000
    error_message = "checkpoint_interval_ms debe ser al menos 1000."
  }
}

variable "parallelism" {
  description = "Cantidad inicial de subtareas; coincide con los dos shards."
  type        = number
  default     = 2
}

variable "parallelism_per_kpu" {
  description = "Subtareas por KPU."
  type        = number
  default     = 2

  validation {
    condition     = var.parallelism_per_kpu >= 1 && var.parallelism_per_kpu <= 8
    error_message = "parallelism_per_kpu debe estar entre 1 y 8."
  }
}

variable "auto_scaling_enabled" {
  description = "Habilita el auto scaling administrado."
  type        = bool
  default     = false
}

variable "watermark_delay_seconds" {
  description = "Desorden maximo esperado para el watermark."
  type        = number
  default     = 10
}

variable "watermark_idle_seconds" {
  description = "Tiempo para considerar idle un shard."
  type        = number
  default     = 30
}

variable "window_size_seconds" {
  description = "Tamano de la ventana tumbling."
  type        = number
  default     = 60
}

variable "allowed_lateness_seconds" {
  description = "Periodo de gracia para eventos tardios."
  type        = number
  default     = 30
}

variable "log_retention_days" {
  description = "Retencion de logs de Flink en CloudWatch."
  type        = number
  default     = 7
}
