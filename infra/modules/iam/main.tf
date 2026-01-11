# 信頼ポリシー（AssumeRole）: ECS タスクからの引き受けを許可
data "aws_iam_policy_document" "ecs_tasks_assume_role" {
  statement {
    sid     = "ECSTasksAssumeRole"
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      # ECS タスク実行サービスプリンシパル
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# IAM ロール本体の作成
resource "aws_iam_role" "task_execution" {
  name = var.role_name
  # 上記で定義した信頼ポリシー
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json
  tags               = var.tags
}

# 必要最小限の実行用ポリシーをアタッチ（AWS 管理ポリシー）
resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy" # イメージ取得/ログ出力等
}

# タスクロール（タスク本体が利用する認可）
resource "aws_iam_role" "task" {
  name               = var.task_role_name
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json
  tags               = var.tags
}

# EFS IAM 認可に必要な最小権限（AP を条件に絞る）
data "aws_iam_policy_document" "task_efs" {
  count = var.efs_access_point_arn != null ? 1 : 0
  statement {
    sid    = "EFSClientAccess"
    effect = "Allow"
    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite",
      "elasticfilesystem:ClientRootAccess",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "elasticfilesystem:AccessPointArn"
      values   = [var.efs_access_point_arn]
    }
  }
}

# EFS IAM 認可に必要な最小権限（AP を条件に絞る）
resource "aws_iam_role_policy" "task_efs" {
  count  = var.efs_access_point_arn != null ? 1 : 0
  name   = "AllowEFSAccessPoint"
  role   = aws_iam_role.task.id
  policy = data.aws_iam_policy_document.task_efs[0].json
}
