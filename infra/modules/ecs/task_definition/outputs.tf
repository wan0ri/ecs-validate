# task_definition_arn
output "task_definition_arn" {
  value = aws_ecs_task_definition.this.arn
}

# task_definition_family
output "task_definition_family" {
  value = aws_ecs_task_definition.this.family
}
