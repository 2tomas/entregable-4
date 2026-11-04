locals {
  name_prefix = "${var.project_name}-${var.environment}"
  object_arn  = "${var.data_bucket_arn}/${var.data_prefix}/*"
}

data "aws_iam_policy_document" "processing_assume_role" {
  statement {
    sid     = "AllowDataProcessingServices"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "kinesisanalytics.amazonaws.com",
        "lambda.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "processing" {
  name               = "${local.name_prefix}-data-processing"
  description        = "Acceso mínimo a un prefijo S3 para Lambda o Amazon Managed Service for Apache Flink."
  assume_role_policy = data.aws_iam_policy_document.processing_assume_role.json
}

data "aws_iam_policy_document" "processing" {
  statement {
    sid       = "ListConfiguredPrefix"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [var.data_bucket_arn]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values = [
        var.data_prefix,
        "${var.data_prefix}/*"
      ]
    }
  }

  statement {
    sid    = "ReadWriteConfiguredPrefix"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [local.object_arn]
  }
}

resource "aws_iam_policy" "processing" {
  name        = "${local.name_prefix}-data-processing-s3"
  description = "Acceso de lectura y escritura limitado a ${var.data_prefix}."
  policy      = data.aws_iam_policy_document.processing.json

}

resource "aws_iam_role_policy_attachment" "processing" {
  role       = aws_iam_role.processing.name
  policy_arn = aws_iam_policy.processing.arn
}

data "aws_iam_policy_document" "audit_assume_role" {
  statement {
    sid     = "AllowConfiguredAuditPrincipals"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = var.audit_principal_arns
    }
  }
}

resource "aws_iam_role" "audit" {
  name               = "${local.name_prefix}-control-plane-audit"
  description        = "Acceso de solo lectura para auditar la infraestructura base."
  assume_role_policy = data.aws_iam_policy_document.audit_assume_role.json

}

data "aws_iam_policy_document" "audit" {
  statement {
    sid    = "ReadNetworkConfiguration"
    effect = "Allow"
    actions = [
      "ec2:DescribeRouteTables",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcEndpoints",
      "ec2:DescribeVpcs"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ReadDataBucketConfiguration"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:GetBucketPublicAccessBlock",
      "s3:GetBucketVersioning",
      "s3:GetEncryptionConfiguration",
      "s3:ListBucket"
    ]
    resources = [var.data_bucket_arn]
  }

  statement {
    sid    = "ReadCoreRoles"
    effect = "Allow"
    actions = [
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListRolePolicies"
    ]
    resources = [
      aws_iam_role.processing.arn,
      aws_iam_role.audit.arn
    ]
  }

  statement {
    sid    = "ReadProcessingPolicy"
    effect = "Allow"
    actions = [
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListPolicyVersions"
    ]
    resources = [aws_iam_policy.processing.arn]
  }
}

resource "aws_iam_policy" "audit" {
  name        = "${local.name_prefix}-control-plane-audit"
  description = "Lectura de configuración de red, S3 e IAM para auditoría."
  policy      = data.aws_iam_policy_document.audit.json

}

resource "aws_iam_role_policy_attachment" "audit" {
  role       = aws_iam_role.audit.name
  policy_arn = aws_iam_policy.audit.arn
}
