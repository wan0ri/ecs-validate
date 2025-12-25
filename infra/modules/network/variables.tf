# リージョン
variable "region" {
  description = "AWSリージョン"
  type        = string
}

# アベイラビリティーゾーンA
variable "az_a" {
  description = "1つ目のAZ名（例: ap-northeast-1a）"
  type        = string
}

# アベイラビリティーゾーンC
variable "az_c" {
  description = "2つ目のAZ名（例: ap-northeast-1c）"
  type        = string
}
