resource "aws_kinesis_stream" "kinesis_stream" {
  name             = "terraform-kinesis-${var.environment}"
  shard_count      = 2
  retention_period = 48
  encryption_type  = "KMS"
  kms_key_id       = aws_kms_key.kinesis.arn

  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
  ]

  stream_mode_details {
    stream_mode = "PROVISIONED"
  }

  tags = {
    Environment = var.environment
  }
}

resource "aws_kms_key" "kinesis" {
  description         = "Clave KMS para Kinesis ${var.environment}"
  enable_key_rotation = true
}


resource "aws_kinesis_firehose_delivery_stream" "extended_s3_stream" {
  name        = "terraform-kinesis-firehose-extended-s3-${var.environment}"
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.kinesis_stream.arn
    role_arn           = aws_iam_role.firehose_role.arn
  }

  extended_s3_configuration {
    role_arn            = aws_iam_role.firehose_role.arn
    bucket_arn          = var.data_bucket_arn
    buffering_size      = 5
    buffering_interval  = 60
    prefix              = "ingesta/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
    error_output_prefix = "errores/!{firehose:error-output-type}/"


    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.firehose.name
      log_stream_name = aws_cloudwatch_log_stream.firehose.name
    }
  }
}

data "aws_iam_policy_document" "firehose_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "firehose_role" {
  name               = "firehose-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.firehose_assume_role.json
}

data "aws_iam_policy_document" "firehose_permissions" {
  statement {
    sid    = "ReadKinesisStream"
    effect = "Allow"

    actions = [
      "kinesis:DescribeStream",
      "kinesis:GetShardIterator",
      "kinesis:GetRecords",
      "kinesis:ListShards"
    ]

    resources = [
      aws_kinesis_stream.kinesis_stream.arn
    ]
  }

  statement {
    sid    = "WriteCloudWatchLogs"
    effect = "Allow"

    actions = [
      "logs:PutLogEvents"
    ]

    resources = [
      aws_cloudwatch_log_stream.firehose.arn
    ]
  }

  statement {
    sid    = "DecryptKinesisStream"
    effect = "Allow"

    actions = [
      "kms:Decrypt"
    ]

    resources = [
      aws_kms_key.kinesis.arn
    ]
  }

  statement {
    sid    = "AccessS3Bucket"
    effect = "Allow"

    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads"
    ]

    resources = [
      var.data_bucket_arn
    ]
  }

  statement {
    sid    = "WriteS3Objects"
    effect = "Allow"

    actions = [
      "s3:AbortMultipartUpload",
      "s3:PutObject"
    ]

    resources = [
      "${var.data_bucket_arn}/*"
    ]
  }
}

resource "aws_iam_role_policy" "firehose_permissions" {
  name   = "firehose-permissions-${var.environment}"
  role   = aws_iam_role.firehose_role.id
  policy = data.aws_iam_policy_document.firehose_permissions.json
}


resource "aws_cloudwatch_log_group" "firehose" {
  name              = "/aws/kinesisfirehose/${var.environment}"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_stream" "firehose" {
  name           = "s3-delivery"
  log_group_name = aws_cloudwatch_log_group.firehose.name
}


resource "aws_cloudwatch_metric_alarm" "read_throughput_exceeded" {
  alarm_name          = "${var.environment}-kinesis-read-throughput-exceeded"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ReadProvisionedThroughputExceeded"
  namespace           = "AWS/Kinesis"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    StreamName = aws_kinesis_stream.kinesis_stream.name
  }
}

resource "aws_cloudwatch_metric_alarm" "write_throughput_exceeded" {
  alarm_name          = "${var.environment}-kinesis-write-throughput-exceeded"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "WriteProvisionedThroughputExceeded"
  namespace           = "AWS/Kinesis"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    StreamName = aws_kinesis_stream.kinesis_stream.name
  }
}
