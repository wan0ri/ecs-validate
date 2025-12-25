# network  モジュールの呼び出し
module "network" {
  source = "./modules/network"

  region = var.region
  az_a   = "ap-northeast-1a" // 検証用に明示
  az_c   = "ap-northeast-1c" // 検証用に明示
}

# SG はネットワーク検出結果を受けて作成（段階構築）
module "security" {
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

# EFS モジュールの呼び出し（後段で有効化）
# module "efs" {
#   source = "./modules/efs"
#   subnet_a_id = module.network.subnet_a_id
#   subnet_c_id = module.network.subnet_c_id
#   efs_sg_id   = module.security.efs_sg_id
#   tags        = var.tags
# }

# 日本語コメント: /32 への切替は、EFSを結線後に module "security" へ
# use_efs_mt_ips = true と efs_mt_ips = module.efs.mount_target_ips を追記して再適用します。
