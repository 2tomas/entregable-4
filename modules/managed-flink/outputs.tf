output "application_name" {
  value = aws_kinesisanalyticsv2_application.this.name
}

output "application_arn" {
  value = aws_kinesisanalyticsv2_application.this.arn
}

output "artifact_bucket_name" {
  value = aws_s3_bucket.artifacts.bucket
}

output "cloudwatch_log_group_name" {
  value = aws_cloudwatch_log_group.application.name
}

output "execution_role_arn" {
  value = aws_iam_role.application.arn
}
