# ECS Service（失敗再現用: 許可していないAZ側のみで配置）
variable "name" {
  description = "ECS Service name"
  type        = string
}

# ECS Cluster名 or ARN
variable "cluster" {
  description = "Cluster name or ARN"
  type        = string
}

# Task定義 ARN
variable "task_definition_arn" {
  description = "Task Definition ARN"
  type        = string
}

# Subnet IDs for service placement
variable "subnet_ids" {
  description = "Subnet IDs for service placement"
  type        = list(string)
}

# Security Group ID for tasks
variable "security_group_id" {
  description = "Security Group ID for tasks"
  type        = string
}

# Assign public IP to tasks
variable "assign_public_ip" {
  description = "Assign public IP to tasks"
  type        = bool
  default     = true
}

# Desired task count
variable "desired_count" {
  description = "Desired task count"
  type        = number
  default     = 1
}
