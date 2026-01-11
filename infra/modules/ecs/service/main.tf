# ECS Service (Fargate)
resource "aws_ecs_service" "this" {
  name            = var.name
  cluster         = var.cluster
  task_definition = var.task_definition_arn
  desired_count   = var.desired_count

  launch_type = "FARGATE"

  network_configuration {
    assign_public_ip = var.assign_public_ip
    security_groups  = [var.security_group_id]
    subnets          = var.subnet_ids
  }
}
