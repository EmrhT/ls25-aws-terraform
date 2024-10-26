# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "db_username" {
  description = "The username for the database"
  type        = string
  sensitive   = true
  default     = "example_username_stage"
}

variable "db_password" {
  description = "The password for the database"
  type        = string
  sensitive   = true
  default     = "example_password_stage"
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "db_name" {
  description = "The name to use for the database"
  type        = string
  default     = "example_database_stage"
}

variable "bt26_iam_role_arn" {
  description = "The ARN of an IAM role to assume in the bt26 AWS account"
  type        = string
  default     = "arn:aws:iam::061051260191:role/bt26-admin-role"
}

variable "bt27_iam_role_arn" {
  description = "The ARN of an IAM role to assume in the bt27 AWS account"
  type        = string
  default     = "arn:aws:iam::160885262681:role/bt27-admin-role"
}

