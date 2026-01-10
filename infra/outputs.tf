# VPC ID
output "vpc_id" {
  description = "デフォルトVPC ID"
  value       = module.network.vpc_id
}

# ECSで利用するサブネットID一覧 (1a/1c)
output "ecs_subnet_ids" {
  description = "ECSで利用するサブネットID一覧 (1a/1c)"
  value       = module.network.ecs_subnet_ids
}

# サブネットCIDR (1a)
output "subnet_a_cidr" {
  description = "ap-northeast-1a のサブネットCIDR"
  value       = module.network.subnet_a_cidr
}

# サブネットCIDR (1c)
output "subnet_c_cidr" {
  description = "ap-northeast-1c のサブネットCIDR"
  value       = module.network.subnet_c_cidr
}

# ECS タスク用 SG ID
output "ecs_sg_id" {
  description = "ECS タスク用 SG ID"
  value       = var.enable_security ? module.security[0].ecs_sg_id : null
}

# EFS 用 SG ID
output "efs_sg_id" {
  description = "EFS 用 SG ID"
  value       = var.enable_security ? module.security[0].efs_sg_id : null
}

# EFS ファイルシステムID
output "efs_id" {
  description = "EFS ファイルシステムID"
  value       = var.enable_efs ? module.efs[0].efs_id : null
}

# EFS マウントターゲットのプライベートIP一覧
output "efs_mount_target_ips" {
  description = "EFS マウントターゲットのプライベートIP一覧"
  value       = var.enable_efs ? module.efs[0].mount_target_ips : []
}

# タスク実行ロール（有効時のみ）
output "task_execution_role_arn" {
  description = "ECS タスク実行ロールの ARN"
  value       = var.enable_iam ? module.iam[0].task_execution_role_arn : null
}

output "task_execution_role_name" {
  description = "ECS タスク実行ロールの名前"
  value       = var.enable_iam ? module.iam[0].task_execution_role_name : null
}
