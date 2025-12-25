# EFS ID と マウントターゲットのIPアドレス
output "efs_id" {
  description = "EFS ファイルシステムID"
  value       = aws_efs_file_system.this.id
}

# マウントターゲットのプライベートIP（存在するAZ分）
output "mount_target_ips" {
  description = "マウントターゲットのプライベートIP（存在するAZ分）"
  value       = local.mt_ips
}

# アクセスポイントのID/ARN/パス
output "access_point_id" {
  description = "EFS アクセスポイントID"
  value       = try(aws_efs_access_point.this[0].id, null)
}

# アクセスポイントのARNは必要に応じて出力
output "access_point_arn" {
  description = "EFS アクセスポイントARN"
  value       = try(aws_efs_access_point.this[0].arn, null)
}

# アクセスポイントのルートパス
output "access_point_path" {
  description = "アクセスポイントのルートパス"
  value       = var.ap_path
}
