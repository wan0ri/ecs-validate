# AWSプロバイダ設定(リージョンと共通タグ)
provider "aws" {
  region = var.region

  default_tags {
    tags = merge({
      "Project"   = "ecs-validate"
      "ManagedBy" = "Terraform"
    }, var.tags)
  }
}
