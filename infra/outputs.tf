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

# ECS タスク用 SG ID（後段で有効化）
# output "ecs_sg_id" {
#   description = "ECS タスク用 SG ID"
#   value       = module.security.ecs_sg_id
# }

# EFS 用 SG ID（後段で有効化）
# output "efs_sg_id" {
#   description = "EFS 用 SG ID"
#   value       = module.security.efs_sg_id
# }
