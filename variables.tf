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

variable "cidr_az_blocks" {
  type = map(any)
  default = {
    a2 = {
      cidr = "10.0.2.0/28"
      zone = "a"
    }
    b2 = {
      cidr = "10.0.2.16/28"
      zone = "b"
    }
    c2 = {
      cidr = "10.0.2.32/28"
      zone = "c"
    }
  }
}
