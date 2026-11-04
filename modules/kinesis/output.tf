output "stream_name" {
  description = "Nombre del Kinesis Data Stream."
  value       = aws_kinesis_stream.kinesis_stream.name
}

output "stream_arn" {
  description = "ARN del Kinesis Data Stream."
  value       = aws_kinesis_stream.kinesis_stream.arn
}

output "kms_key_arn" {
  description = "ARN de la CMK que cifra el stream."
  value       = aws_kms_key.kinesis.arn
}

output "firehose_name" {
  description = "Nombre del delivery stream hacia la capa Bronze."
  value       = aws_kinesis_firehose_delivery_stream.extended_s3_stream.name
}
