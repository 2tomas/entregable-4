output "bucket_arn" {
  description = "ARN del bucket del Data Lake"
  value       = aws_s3_bucket.data_lake.arn
}

output "bucket_name" {
  description = "Nombre del bucket del Data Lake"
  value       = aws_s3_bucket.data_lake.bucket
}