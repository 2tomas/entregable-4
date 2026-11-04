data "aws_caller_identity" "current" {}

locals {
  name_prefix  = "${var.project_name}-${var.environment}"
  artifact_key = "flink/realtime-metrics-flink-1.0.0.jar"
}

resource "aws_s3_bucket" "artifacts" {
  bucket = lower("${local.name_prefix}-flink-artifacts-${data.aws_caller_identity.current.account_id}")
}

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "application" {
  bucket      = aws_s3_bucket.artifacts.id
  key         = local.artifact_key
  source      = var.flink_jar_path
  source_hash = filemd5(var.flink_jar_path)

  depends_on = [
    aws_s3_bucket_versioning.artifacts,
    aws_s3_bucket_server_side_encryption_configuration.artifacts,
    aws_s3_bucket_public_access_block.artifacts
  ]
}

resource "aws_cloudwatch_log_group" "application" {
  name              = "/aws/managed-flink/${local.name_prefix}-realtime-metrics"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_stream" "application" {
  name           = "application"
  log_group_name = aws_cloudwatch_log_group.application.name
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    sid     = "ManagedFlinkAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["kinesisanalytics.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "application" {
  name               = "${local.name_prefix}-managed-flink"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "application" {
  statement {
    sid    = "ReadInputStream"
    effect = "Allow"
    actions = [
      "kinesis:DescribeStream",
      "kinesis:DescribeStreamSummary",
      "kinesis:GetRecords",
      "kinesis:GetShardIterator",
      "kinesis:ListShards"
    ]
    resources = [var.kinesis_stream_arn]
  }

  dynamic "statement" {
    for_each = var.kinesis_kms_key_arn == null ? [] : [var.kinesis_kms_key_arn]
    content {
      sid       = "DecryptInputStream"
      effect    = "Allow"
      actions   = ["kms:Decrypt"]
      resources = [statement.value]
    }
  }

  statement {
    sid       = "ListArtifactBucket"
    effect    = "Allow"
    actions   = ["s3:GetBucketLocation", "s3:ListBucket"]
    resources = [aws_s3_bucket.artifacts.arn]
  }

  statement {
    sid    = "ReadApplicationArtifact"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion"
    ]
    resources = ["${aws_s3_bucket.artifacts.arn}/${local.artifact_key}"]
  }

  statement {
    sid    = "DiscoverCloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
    resources = ["*"]
  }

  statement {
    sid       = "WriteApplicationLogs"
    effect    = "Allow"
    actions   = ["logs:PutLogEvents"]
    resources = [aws_cloudwatch_log_stream.application.arn]
  }
}

resource "aws_iam_role_policy" "application" {
  name   = "${local.name_prefix}-managed-flink"
  role   = aws_iam_role.application.id
  policy = data.aws_iam_policy_document.application.json
}

resource "aws_kinesisanalyticsv2_application" "this" {
  name                   = "${local.name_prefix}-realtime-metrics"
  description            = "Metricas por usuario con event time, watermarks, ventanas y KeyedState."
  runtime_environment    = var.runtime_environment
  service_execution_role = aws_iam_role.application.arn
  start_application      = var.start_application
  force_stop             = true

  application_configuration {
    application_code_configuration {
      code_content {
        s3_content_location {
          bucket_arn     = aws_s3_bucket.artifacts.arn
          file_key       = aws_s3_object.application.key
          object_version = aws_s3_object.application.version_id
        }
      }

      code_content_type = "ZIPFILE"
    }

    application_snapshot_configuration {
      snapshots_enabled = true
    }

    environment_properties {
      property_group {
        property_group_id = "InputProperties"
        property_map = {
          "stream.arn"                         = var.kinesis_stream_arn
          "stream.initial.position"            = "LATEST"
          "source.parallelism"                 = tostring(var.parallelism)
          "watermark.out.of.orderness.seconds" = tostring(var.watermark_delay_seconds)
          "watermark.idleness.seconds"         = tostring(var.watermark_idle_seconds)
          "window.size.seconds"                = tostring(var.window_size_seconds)
          "window.allowed.lateness.seconds"    = tostring(var.allowed_lateness_seconds)
        }
      }
    }

    flink_application_configuration {
      checkpoint_configuration {
        configuration_type            = "CUSTOM"
        checkpointing_enabled         = true
        checkpoint_interval           = var.checkpoint_interval_ms
        min_pause_between_checkpoints = 5000
      }

      monitoring_configuration {
        configuration_type = "CUSTOM"
        log_level          = "INFO"
        metrics_level      = "TASK"
      }

      parallelism_configuration {
        configuration_type   = "CUSTOM"
        auto_scaling_enabled = var.auto_scaling_enabled
        parallelism          = var.parallelism
        parallelism_per_kpu  = var.parallelism_per_kpu
      }
    }

    run_configuration {
      application_restore_configuration {
        application_restore_type = "RESTORE_FROM_LATEST_SNAPSHOT"
      }

      flink_run_configuration {
        allow_non_restored_state = false
      }
    }
  }

  cloudwatch_logging_options {
    log_stream_arn = aws_cloudwatch_log_stream.application.arn
  }

  depends_on = [aws_iam_role_policy.application]
}
