# network  モジュールの呼び出し
module "network" {
  source = "./modules/network"

  region = var.region
  az_a   = "ap-northeast-1a" // 検証用に明示
  az_c   = "ap-northeast-1c" // 検証用に明示
}

# SG はネットワーク検出結果を受けて作成（段階構築）
module "security" {
  count  = var.enable_security ? 1 : 0
  source = "./modules/security"

  vpc_id        = module.network.vpc_id
  subnet_a_cidr = module.network.subnet_a_cidr
  subnet_c_cidr = module.network.subnet_c_cidr

  # 初期は片側AZのみ・狭い/28へ制限（allow_both_azs=false）
  lockdown_mode  = true
  allow_both_azs = false
  # ログ初期化に必要なHTTPSアウトバウンドは許可
  allow_https_egress = true

  # 手動で明示する場合は以下を使う（例）
  // cidrs_allowed = ["10.0.0.0/28"]

  tags = var.tags
}

# EFS モジュールの呼び出し（段階適用: まず/28のまま）
module "efs" {
  count  = var.enable_efs ? 1 : 0
  source = "./modules/efs"

  subnet_a_id = module.network.subnet_a_id
  subnet_c_id = module.network.subnet_c_id
  # security モジュールは count 化しているため配列参照に変更
  efs_sg_id = module.security[0].efs_sg_id
  tags      = var.tags
}

# 既存のモジュールアドレスを count 付きの新アドレスへ移行
moved {
  from = module.security
  to   = module.security[0]
}

moved {
  from = module.efs
  to   = module.efs[0]
}

# IAM（タスク実行ロール）モジュールの呼び出し（トグルで制御）
module "iam" {
  count  = var.enable_iam ? 1 : 0
  source = "./modules/iam"

  role_name            = "ecsTaskExecutionRole-ecs-validate"
  task_role_name       = "ecsTaskRole-ecs-validate"
  efs_access_point_arn = module.efs[0].access_point_arn
  tags                 = var.tags
}

# CloudWatchlogs モジュールの呼び出し
module "logs" {
  count  = var.enable_logs ? 1 : 0
  source = "./modules/logs"

  name              = "/ecs/ecs-validate"
  retention_in_days = 1
  tags              = var.tags
}

# 依存関係を考慮した有効化フラグ（LSPの誤検知も抑制）
locals {
  enable_ecs_cluster = var.enable_ecs
  enable_ecs_taskdef = var.enable_ecs && var.enable_efs && var.enable_iam && var.enable_logs
  enable_ecs_service = local.enable_ecs_taskdef && var.enable_security
}

# ECS Clusterモジュールの呼び出し
module "ecs_cluster" {
  count  = local.enable_ecs_cluster ? 1 : 0
  source = "./modules/ecs/cluster"

  name = "ecs-validate"
}

# ECS TaskDefinitionモジュールの呼び出し
module "ecs_task_definition" {
  count  = local.enable_ecs_taskdef ? 1 : 0
  source = "./modules/ecs/task_definition"

  name                = "ap-repro"
  execution_role_arn  = module.iam[0].task_execution_role_arn
  task_role_arn       = module.iam[0].task_role_arn
  log_group_name      = module.logs[0].log_group_name
  region              = var.region
  efs_file_system_id  = module.efs[0].efs_id
  efs_access_point_id = module.efs[0].access_point_id
}

# ECS Service（失敗再現用: 許可していないAZ側のみで配置）
module "ecs_service" {
  count  = local.enable_ecs_service ? 1 : 0
  source = "./modules/ecs/service"

  name                = "ap-repro"
  cluster             = module.ecs_cluster[0].name
  task_definition_arn = module.ecs_task_definition[0].task_definition_arn
  security_group_id   = module.security[0].ecs_sg_id
  # allow_both_azs=false のため、1aのみNFS許可。
  # ここでは1cのみを渡し、NFSエグレスを塞いで失敗を再現する。
  subnet_ids       = [module.network.subnet_c_id]
  assign_public_ip = true
  desired_count    = 1
}
