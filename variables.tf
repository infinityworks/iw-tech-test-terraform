variable "ssh_key" {
  description = "The ssh key to use"
  type        = string
  default     = "demo"
}

variable "aws_provider_region" {
  description = "The AWS provider region"
  type        = string
  default     = "us-east-1"
}

variable "aws_provider_profile" {
  description = "The AWS provider profile"
  type        = string
  default     = "sandbox-acloudguru"
}