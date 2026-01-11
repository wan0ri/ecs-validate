# execution_role_arn
variable "execution_role_arn" {
  type = string
}

# task_role_arn
variable "task_role_arn" {
  type = string
}

# name (task family)
variable "name" {
  type = string
}

# log_group_name
variable "log_group_name" {
  type = string
}

# region
variable "region" {
  type = string
}

# efs_file_system_id
variable "efs_file_system_id" {
  type = string
}

# efs_access_point_id
variable "efs_access_point_id" {
  type = string
}
