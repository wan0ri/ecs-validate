# デフォルトVPCと既定サブネット(1a/1c)を自動検出
data "aws_vpc" "default" {
  default = true
}

# デフォルトVPC内の「AZデフォルトサブネット」を収集
data "aws_subnets" "default_vpc_defaults" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

# 各サブネットの詳細（for_eachで展開）
data "aws_subnet" "all" {
  for_each = toset(data.aws_subnets.default_vpc_defaults.ids)
  id       = each.value
}

locals {
  # AZごとに一致するサブネットを抽出
  subnet_a = [for s in data.aws_subnet.all : s if s.availability_zone == var.az_a]
  subnet_c = [for s in data.aws_subnet.all : s if s.availability_zone == var.az_c]

  subnet_a_id   = length(local.subnet_a) > 0 ? local.subnet_a[0].id : null
  subnet_c_id   = length(local.subnet_c) > 0 ? local.subnet_c[0].id : null
  subnet_a_cidr = length(local.subnet_a) > 0 ? local.subnet_a[0].cidr_block : null
  subnet_c_cidr = length(local.subnet_c) > 0 ? local.subnet_c[0].cidr_block : null
}
