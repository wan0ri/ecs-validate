# 後続 (ECSモジュール) から参照するための出力
output "log_group_name" {
  description = "CloudWatich Logs グループ名"
  value       = var.name
}
