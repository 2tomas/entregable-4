output "vpc_id" {
  description = "ID de la VPC heredada de la infraestructura base."
  value       = module.network.vpc_id
}

output "data_lake_bucket_name" {
  description = "Bucket Bronze que recibe datos de Firehose."
  value       = module.storage.bucket_name
}

output "kinesis_stream_name" {
  description = "Nombre del stream consumido por Firehose y Flink."
  value       = module.kinesis.stream_name
}

output "kinesis_stream_arn" {
  description = "ARN del stream consumido por Flink."
  value       = module.kinesis.stream_arn
}

output "flink_application_name" {
  description = "Nombre de la aplicacion Managed Flink."
  value       = module.managed_flink.application_name
}

output "flink_application_arn" {
  description = "ARN de la aplicacion Managed Flink."
  value       = module.managed_flink.application_arn
}

output "flink_artifact_bucket_name" {
  description = "Bucket versionado que contiene el fat JAR."
  value       = module.managed_flink.artifact_bucket_name
}

output "flink_log_group_name" {
  description = "CloudWatch Log Group de la aplicacion."
  value       = module.managed_flink.cloudwatch_log_group_name
}

output "processing_role_arn" {
  description = "Rol de procesamiento conservado de la entrega 2."
  value       = module.identity.processing_role_arn
}

output "audit_role_arn" {
  description = "Rol de auditoria conservado de la entrega 2."
  value       = module.identity.audit_role_arn
}
