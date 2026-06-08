variable "aws_region" {
  description = "AWS region for the consulting demo environment"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "Name prefix for provisioned resources"
  type        = string
  default     = "devops-consulting"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to access SSH"
  type        = string
  default     = "0.0.0.0/0"
}

variable "ssh_public_key" {
  description = "Public key for EC2 SSH access"
  type        = string
  sensitive   = true
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}
