module "network" {
  source = "../../modules/network"

  project_name       = var.project_name
  environment        = var.environment
  aws_region         = var.aws_region
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
}

module "storage" {
  source = "../../modules/storage"

  project_name = var.project_name
  environment  = var.environment
}

module "identity" {
  source = "../../modules/identity"

  project_name         = var.project_name
  environment          = var.environment
  data_bucket_arn      = module.storage.bucket_arn
  data_prefix          = var.data_prefix
  audit_principal_arns = var.audit_principal_arns
}

module "kinesis" {
  source = "../../modules/kinesis"

  environment     = var.environment
  data_bucket_arn = module.storage.bucket_arn
}

module "managed_flink" {
  source = "../../modules/managed-flink"

  project_name             = var.project_name
  environment              = var.environment
  kinesis_stream_arn       = module.kinesis.stream_arn
  kinesis_kms_key_arn      = module.kinesis.kms_key_arn
  flink_jar_path           = abspath(var.flink_jar_path)
  runtime_environment      = var.runtime_environment
  start_application        = var.start_application
  checkpoint_interval_ms   = var.checkpoint_interval_ms
  parallelism              = var.parallelism
  parallelism_per_kpu      = var.parallelism_per_kpu
  auto_scaling_enabled     = var.auto_scaling_enabled
  watermark_delay_seconds  = var.watermark_delay_seconds
  watermark_idle_seconds   = var.watermark_idle_seconds
  window_size_seconds      = var.window_size_seconds
  allowed_lateness_seconds = var.allowed_lateness_seconds
  log_retention_days       = var.log_retention_days
}
