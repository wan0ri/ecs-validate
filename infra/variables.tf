# リージョン
variable "region" {
  description = "AWSリージョン"
  type        = string
  default     = "ap-northeast-1" // 東京リージョン
}

# 共通タグ
variable "tags" {
  description = "共通タグ"
  type        = map(string)
  default     = {}
}

# SGモジュール有効化フラグ
variable "enable_security" {
  description = "Security Group モジュールを有効化するか"
  type        = bool
  default     = true
}

# EFSモジュール有効化フラグ
variable "enable_efs" {
  description = "EFS モジュールを有効化するか"
  type        = bool
  default     = true
}

# IAMモジュール有効化フラグ
variable "enable_iam" {
  description = "IAM(タスク実行ロール等) モジュールを有効化するか"
  type        = bool
  default     = false
}

# CloudWatch Logsモジュール有効化フラグ
variable "enable_logs" {
  description = "CloudWatch Logs モジュールを有効化するか"
  type        = bool
  default     = false
}

# ECSモジュール有効化フラグ
variable "enable_ecs" {
  description = "ECS(Cluster/Task/Service) モジュールを有効化するか"
  type        = bool
  default     = false
}
