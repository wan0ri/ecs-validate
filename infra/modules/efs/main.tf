# EFS 本体と、存在するAZごとのマウントターゲットを作成
resource "aws_efs_file_system" "this" {
  performance_mode = "generalPurpose" # 検証のため標準性能
  throughput_mode  = "bursting"

  tags = merge({ Name = "efs-ecs-validate" }, var.tags)
}

# 1a 用マウントターゲット（サブネットが存在する場合のみ）
resource "aws_efs_mount_target" "mt_a" {
  count           = var.subnet_a_id == null ? 0 : 1
  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = var.subnet_a_id
  security_groups = [var.efs_sg_id]
}

# 1c 用マウントターゲット（サブネットが存在する場合のみ）
resource "aws_efs_mount_target" "mt_c" {
  count           = var.subnet_c_id == null ? 0 : 1
  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = var.subnet_c_id
  security_groups = [var.efs_sg_id]
}

# マウントターゲットの ENI からプライベートIPを取得
data "aws_network_interface" "mt_a_eni" {
  count = length(aws_efs_mount_target.mt_a) == 0 ? 0 : 1
  id    = aws_efs_mount_target.mt_a[0].network_interface_id
}

# マウントターゲットの ENI からプライベートIPを取得
data "aws_network_interface" "mt_c_eni" {
  count = length(aws_efs_mount_target.mt_c) == 0 ? 0 : 1
  id    = aws_efs_mount_target.mt_c[0].network_interface_id
}

# マウントターゲットのプライベートIP一覧
locals {
  mt_ips = compact([
    length(data.aws_network_interface.mt_a_eni) > 0 ? data.aws_network_interface.mt_a_eni[0].private_ip : null,
    length(data.aws_network_interface.mt_c_eni) > 0 ? data.aws_network_interface.mt_c_eni[0].private_ip : null,
  ])
}

# アクセスポイント（検証では1つだけ作成）
resource "aws_efs_access_point" "this" {
  count          = var.ap_enabled ? 1 : 0
  file_system_id = aws_efs_file_system.this.id

  # ルートディレクトリ設定。存在しない場合は creation_info で作成
  root_directory {
    path = var.ap_path

    dynamic "creation_info" {
      for_each = var.ap_root_create ? [1] : []
      content {
        owner_gid   = var.ap_posix_gid
        owner_uid   = var.ap_posix_uid
        permissions = "0755"
      }
    }
  }

  # デフォルトのPOSIXユーザー（アプリがUID/GIDを持たない場合の代替）
  posix_user {
    gid = var.ap_posix_gid
    uid = var.ap_posix_uid
  }

  tags = merge({ Name = "efs-ap-ecs-validate" }, var.tags)
}
