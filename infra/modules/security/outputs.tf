# 作成したECSタスク用のIDを出力
output "ecs_sg_id" {
  description = "ECS タスク用 SG ID"
  value       = var.enabled ? aws_security_group.ecs[0].id : null
}

# 作成したEFS用のIDを出力（後段で有効化）
output "efs_sg_id" {
  description = "EFS 用 SG ID"
  value       = var.enabled ? aws_security_group.efs[0].id : null
}
