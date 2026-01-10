# 作成する IAM ロールの名称（既存と衝突しないよう注意）
variable "role_name" {
  description = "ECS タスク実行ロール名"
  type        = string
  default     = "ecsTaskExecutionRole-ecs-validate"
}

# ロールに付与する共通タグ（任意）
variable "tags" {
  description = "リソース共通タグ"
  type        = map(string)
  default     = {}
}
