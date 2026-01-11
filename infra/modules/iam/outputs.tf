# タスク実行ロールの ARN を出力
output "task_execution_role_arn" {
  description = "ECS タスク実行ロールの ARN"
  value       = aws_iam_role.task_execution.arn
}

# タスク実行ロールの名前を出力
output "task_execution_role_name" {
  description = "ECS タスク実行ロールの名前"
  value       = aws_iam_role.task_execution.name
}

# タスクロールの ARN/Name を出力
output "task_role_arn" {
  description = "ECS タスクロールの ARN"
  value       = aws_iam_role.task.arn
}

output "task_role_name" {
  description = "ECS タスクロールの名前"
  value       = aws_iam_role.task.name
}
