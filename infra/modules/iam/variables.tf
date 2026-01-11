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

# タスクロール名（アプリ用）
variable "task_role_name" {
  description = "ECS タスクロール名（タスクが取得する認可）"
  type        = string
  default     = "ecsTaskRole-ecs-validate"
}

# EFS アクセスポイント ARN（EFS IAM 認可の条件に利用）
variable "efs_access_point_arn" {
  description = "EFS Access Point ARN（ポリシー条件に使用、無ければスキップ）"
  type        = string
  default     = null
}
