# ECS Service（失敗再現用: 許可していないAZ側のみで配置）
output "service_name" {
  value = aws_ecs_service.this.name
}
