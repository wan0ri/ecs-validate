# ネットワーク関連のアウトプット
output "vpc_id" {
  description = "デフォルトVPC ID"
  value       = data.aws_vpc.default.id
}

# サブネットID（存在しない場合は null）
output "subnet_a_id" {
  description = "ap-northeast-1a のサブネットID（存在しない場合は null）"
  value       = local.subnet_a_id
}

# サブネットID（存在しない場合は null）
output "subnet_c_id" {
  description = "ap-northeast-1c のサブネットID（存在しない場合は null）"
  value       = local.subnet_c_id
}

# サブネットCIDR
output "subnet_a_cidr" {
  description = "ap-northeast-1a のサブネットCIDR"
  value       = local.subnet_a_cidr
}

# サブネットCIDR
output "subnet_c_cidr" {
  description = "ap-northeast-1c のサブネットCIDR"
  value       = local.subnet_c_cidr
}

# ECSで利用するサブネット（1a/1cの存在するもののみ）
output "ecs_subnet_ids" {
  description = "ECSで利用するサブネット（1a/1cの存在するもののみ）"
  value       = compact([local.subnet_a_id, local.subnet_c_id])
}
