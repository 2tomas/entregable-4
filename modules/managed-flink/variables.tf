variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "kinesis_stream_arn" {
  type = string
}

variable "kinesis_kms_key_arn" {
  type     = string
  default  = null
  nullable = true
}

variable "flink_jar_path" {
  type = string
}

variable "runtime_environment" {
  type = string
}

variable "start_application" {
  type = bool
}

variable "checkpoint_interval_ms" {
  type = number
}

variable "parallelism" {
  type = number
}

variable "parallelism_per_kpu" {
  type = number
}

variable "auto_scaling_enabled" {
  type = bool
}

variable "watermark_delay_seconds" {
  type = number
}

variable "watermark_idle_seconds" {
  type = number
}

variable "window_size_seconds" {
  type = number
}

variable "allowed_lateness_seconds" {
  type = number
}

variable "log_retention_days" {
  type = number
}
