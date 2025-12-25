# ap-northeast-1a のサブネットID（null 可）
variable "subnet_a_id" {
  description = "ap-northeast-1a のサブネットID（null 可）"
  type        = string
  default     = null
}

# ap-northeast-1c のサブネットID（null 可）
variable "subnet_c_id" {
  description = "ap-northeast-1c のサブネットID（null 可）"
  type        = string
  default     = null
}

# EFS 用セキュリティグループID
variable "efs_sg_id" {
  description = "EFS 用セキュリティグループID"
  type        = string
}

# 共通タグ
variable "tags" {
  description = "共通タグ"
  type        = map(string)
  default     = {}
}

# モジュールの有効/無効（段階適用のためのフラグ）
variable "enabled" {
  description = "このモジュールを有効化するか"
  type        = bool
  default     = true
}

# アクセスポイントの有無（検証では1つ作成）
variable "ap_enabled" {
  description = "アクセスポイントを作成するかどうか"
  type        = bool
  default     = true
}

# アクセスポイントのルートパス（EFS上のディレクトリ）
variable "ap_path" {
  description = "アクセスポイントのルートパス"
  type        = string
  default     = "/data"
}

# アクセスポイントのPOSIXユーザー/グループ（検証用デフォルト 1000/1000）
variable "ap_posix_uid" {
  description = "アクセスポイントで使用するPOSIX UID"
  type        = number
  default     = 1000
}

variable "ap_posix_gid" {
  description = "アクセスポイントで使用するPOSIX GID"
  type        = number
  default     = 1000
}

# ルートディレクトリが存在しない場合に自動作成するか
variable "ap_root_create" {
  description = "ルートディレクトリが存在しない場合に作成するかどうか"
  type        = bool
  default     = true
}
