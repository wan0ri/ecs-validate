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
