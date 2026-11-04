output "state_bucket_name" {
  description = "Nombre del bucket S3 que almacena los estados remotos."
  value       = aws_s3_bucket.tf_state.bucket
}

output "state_bucket_arn" {
  description = "ARN del bucket S3 que almacena los estados remotos."
  value       = aws_s3_bucket.tf_state.arn
}

