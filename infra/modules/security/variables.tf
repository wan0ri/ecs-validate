# 有効/無効（段階適用のためのフラグ）
variable "enabled" {
  description = "このモジュールを有効化するか"
  type        = bool
  default     = true
}

# VPC ID
variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

# ap-northeast-1a のサブネットCIDR（狭いCIDR算出の元）
variable "subnet_a_cidr" {
  description = "ap-northeast-1a のサブネットCIDR（狭いCIDR算出の元）"
  type        = string
  default     = null
}

# ap-northeast-1c のサブネットCIDR（狭いCIDR算出の元）
variable "subnet_c_cidr" {
  description = "ap-northeast-1c のサブネットCIDR（狭いCIDR算出の元）"
  type        = string
  default     = null
}

# セキュリティグループのアウトバウンド制限モード
variable "lockdown_mode" {
  description = "true の場合、ECS SGのアウトバウンドを2049/TCP + 指定CIDRのみに制限"
  type        = bool
  default     = true
}

# 両AZ分の狭いCIDRを許可するかどうか
variable "allow_both_azs" {
  description = "true の場合、両AZ分の狭いCIDRを許可。false なら片側のみ"
  type        = bool
  default     = false
}

# 手動で指定する許可CIDR。未指定時は subnet_*_cidr から /28 を自動生成
variable "cidrs_allowed" {
  description = "手動で指定する許可CIDR。未指定時は subnet_*_cidr から /28 を自動生成"
  type        = list(string)
  default     = []
}

# EFSマウントターゲットの実IP(/32)をアウトバウンド許可に使用するかどうか（デフォルト無効）
variable "use_efs_mt_ips" {
  description = "true の場合、EFSマウントターゲットの実IP(/32)をアウトバウンド許可に使用する"
  type        = bool
  default     = false
}

# EFSマウントターゲットのプライベートIP一覧（/32で使用）（デフォルト空）
variable "efs_mt_ips" {
  description = "EFSマウントターゲットのプライベートIP一覧（/32で使用）"
  type        = list(string)
  default     = []
}

# 共通タグ
variable "tags" {
  description = "共通タグ"
  type        = map(string)
  default     = {}
}
