# ロググループ名
variable "name" {
  description = "CloudWatch ロググループ名"
  type        = string
  default     = "/ecs/ecs-validate"
}

# 保持期間（日）。検証では短期(1日)でコスト最小化。
variable "retention_in_days" {
  description = "ログの保持期間（日）"
  type        = number
  default     = 1
}

# 共通タグ（プロバイダ default_tags とマージ）
variable "tags" {
  description = "共通タグ"
  type        = map(string)
  default     = {}
}
