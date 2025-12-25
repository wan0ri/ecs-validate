# ECS 用SG と EFS 用SG を作成
locals {
  # /28 へ狭めるための newbits=8 を利用
  narrow_a = var.subnet_a_cidr != null ? cidrsubnet(var.subnet_a_cidr, 8, 0) : null
  narrow_c = var.subnet_c_cidr != null ? cidrsubnet(var.subnet_c_cidr, 8, 0) : null

  auto_cidrs = var.allow_both_azs ? compact([local.narrow_a, local.narrow_c]) : compact([local.narrow_a])

  # 手動指定があればそれを優先、なければ自動算出
  egress_cidrs = length(var.cidrs_allowed) > 0 ? var.cidrs_allowed : local.auto_cidrs

  # /32 で使うために、EFS MT の実IPからCIDR表記を生成
  mt_cidr32 = [for ip in var.efs_mt_ips : "${ip}/32"]
}

# 既存リソースからcount付きリソースへのアドレス移行
moved {
  from = aws_security_group.ecs
  to   = aws_security_group.ecs[0]
}

moved {
  from = aws_security_group.efs
  to   = aws_security_group.efs[0]
}

# ECS タスク用セキュリティグループ
resource "aws_security_group" "ecs" {
  count       = var.enabled ? 1 : 0
  name        = "ecs-sg"
  description = "ECS tasks SG"
  vpc_id      = var.vpc_id

  # lockdown=false の場合は全アウトバウンド許可
  dynamic "egress" {
    for_each = var.lockdown_mode ? [] : [1]
    content {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = merge({ Name = "ecs-sg" }, var.tags)
}

# lockdown=true の場合のみ、2049/TCP を狭いCIDRへ許可
resource "aws_security_group_rule" "ecs_egress_efs_2049" {
  for_each          = var.enabled && var.lockdown_mode && !var.use_efs_mt_ips ? toset(local.egress_cidrs) : toset([])
  type              = "egress"
  from_port         = 2049
  to_port           = 2049
  protocol          = "tcp"
  cidr_blocks       = [each.value]
  security_group_id = aws_security_group.ecs[0].id
  description       = "Allow NFS to EFS MT (restricted CIDR)"
}

# /32 のマウントターゲットIPで絞るルール（オプション）
resource "aws_security_group_rule" "ecs_egress_efs_2049_mt" {
  for_each          = var.enabled && var.lockdown_mode && var.use_efs_mt_ips ? toset(local.mt_cidr32) : toset([])
  type              = "egress"
  from_port         = 2049
  to_port           = 2049
  protocol          = "tcp"
  cidr_blocks       = [each.value]
  security_group_id = aws_security_group.ecs[0].id
  description       = "Allow NFS to EFS MT (per /32)"
}

# EFS 用セキュリティグループ
resource "aws_security_group" "efs" {
  count       = var.enabled ? 1 : 0
  name        = "efs-sg"
  description = "EFS SG"
  vpc_id      = var.vpc_id

  # インバウンドは ECS SG からの 2049/TCP のみ許可
  ingress {
    description     = "ECS tasks to EFS NFS"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs[0].id]
  }

  # アウトバウンドは制限不要のため全許可（EFSは発信しない想定）
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({ Name = "efs-sg" }, var.tags)
}
