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