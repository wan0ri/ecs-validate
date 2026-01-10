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

  # 手動で明示する場合は以下を使う（例）
  // cidrs_allowed = ["10.0.0.0/28"]

  tags = var.tags
}

# EFS モジュールの呼び出し（段階適用: まず/28のまま）
module "efs" {
  count       = var.enable_efs ? 1 : 0
  source      = "./modules/efs"
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

  role_name = "ecsTaskExecutionRole-ecs-validate"
  tags      = var.tags
}

# CloudWatchlogs モジュールの呼び出し
module "logs" {

  count  = var.enable_logs ? 1 : 0
  source = "./modules/logs"

  name              = "/ecs/ecs-validate"
  retention_in_days = 1
  tags              = var.tags
}
