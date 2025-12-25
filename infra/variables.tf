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
