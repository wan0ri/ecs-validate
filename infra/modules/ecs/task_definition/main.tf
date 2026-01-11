# ECS Task Definition
resource "aws_ecs_task_definition" "this" {
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn
  family                   = var.name
  container_definitions = jsonencode([
    {
      name      = "app"
      image     = "public.ecr.aws/docker/library/busybox:latest"
      command   = ["sh", "-c", "echo start && ls -al /data && sleep 3600"]
      essential = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.log_group_name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
      mountPoints = [
        {
          containerPath = "/data"
          sourceVolume  = "efs_data"
          readOnly      = false
        }
      ]
    }
  ])
  volume {
    name = "efs_data"
    efs_volume_configuration {
      file_system_id     = var.efs_file_system_id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = var.efs_access_point_id
        iam             = "ENABLED"
      }
    }
  }
}
