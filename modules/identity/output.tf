output "processing_role_arn" {
  description = "ARN del rol de ejecución para servicios de procesamiento de datos."
  value       = aws_iam_role.processing.arn
}

output "processing_policy_arn" {
  description = "ARN de la política S3 asociada al rol de procesamiento."
  value       = aws_iam_policy.processing.arn
}

output "audit_role_arn" {
  description = "ARN del rol de solo lectura para el plano de control."
  value       = aws_iam_role.audit.arn
}

output "audit_policy_arn" {
  description = "ARN de la política de auditoría del plano de control."
  value       = aws_iam_policy.audit.arn
}
