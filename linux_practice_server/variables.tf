# Variables are to parameterize code and make it reusable.
variable "region" {
  type    = string
  default = "us-east-1"
}

variable "availability_zone" {
  type    = string
  default = "us-east-1a"
}

variable "instance_type" {
  type    = string
  # t3.small is a burstable general-purpose EC2 instance with 2 vCPUs, 2 GiB RAM, EBS-only storage, and up to 5 Gbps network bandwidth.
  # “Burstable” means the instance has a guaranteed baseline CPU level most of the time, but it can temporarily go faster above that baseline when needed by using CPU credits it earned while idle or lightly loaded. AWS documents T-family instances this way: they accrue CPU credits below baseline and spend them when they burst above baseline.
  default = "t3.small"
}

variable "ebs_type" {
  type    = string
  default = "gp3"
}

variable "repo_url" {
  type        = string
  description = "HTTPS link to Git repo to clone on boot. Leave empty to skip."
  default     = "https://github.com/Qingyu255/Learn-Linux.git"
}
