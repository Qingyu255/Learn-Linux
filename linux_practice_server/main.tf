# This block tells Terraform to :
# - use the AWS provider
# - authenticate using the AWS CLI profile named learnlinux
# - create/query resources in the AWS region stored in var.region
provider "aws" {
  profile = "learnlinux"
  region = var.region
}

# data is used to fetch information about existing infrastructure not managed by the current code. They are not resources
# Canonical public SSM parameter for Ubuntu 24.04 x86-64 (amd64), gp3-backed EC2 AMI
# This basically says: “Go ask AWS SSM Parameter Store for the value stored at this path.”
data "aws_ssm_parameter" "ubuntu_2404_amd64" {
  name = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-${var.ebs_type}/ami-id"
}
# This allows us to fetch the latest correct Ubuntu image dynamically instead of hardcoding an AMI ID that may become outdated or unavailable in the future.

# The following 2 blocks is just fetching the default VPC and its subnets so we can use them for our EC2 instance. We could also create our own VPC and subnets, but using the default ones is simpler for this lab.
# “Find the AWS account’s default VPC in this region.”
data "aws_vpc" "default" {
  default = true
}

# “Find all subnets whose vpc-id matches the default VPC’s ID.”
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "availability-zone"
    values = [var.availability_zone]
  }
}

# Resources:
# This creates a security group inside the default VPC.
resource "aws_security_group" "tlpi_lab" {
  name        = "tlpi-spot-lab-sg"
  description = "SSM-only access for TLPI spot lab"
  vpc_id      = data.aws_vpc.default.id

  # No ingress rules on purpose, meaning no inbound traffic (ssh, http, https, anything) is allowed to the instance from the internet. We will only be able to access it via SSM Session Manager, which does not require any open ports.

  # Allow all outbound traffic to anywhere.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tlpi-spot-lab-sg"
  }
}

# This creates an IAM role that the EC2 instance can assume.
# Why EC2 needs a role:
# - To allow the instance to call AWS APIs on our behalf (in this case, to allow SSM Session Manager to work, the instance needs permissions to communicate with SSM).
resource "aws_iam_role" "ec2_ssm_role" {
  name = "tlpi-spot-lab-ec2-ssm-role"

  # This is the role’s trust policy (trust policy = who can assume the role)
  # “Allow the EC2 service to assume this role.”
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach Systems Manager policy to the role we just created. This is what gives the EC2 instance the necessary permissions to work with SSM Session Manager.
# It allows the EC2 instance to:

# register with Systems Manager
# communicate with SSM
# participate in Session Manager sessions
# So this is the key permission piece for SSM access.
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# An EC2 instance cannot directly attach an IAM role by name.
# Instead, EC2 uses an instance profile, which is basically a wrapper/container around the IAM role for EC2 usage.
# So the chain is:
# IAM role exists
# instance profile wraps that role
# EC2 instance attaches the instance profile
resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "tlpi-spot-lab-ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm_role.name
}

# This block creates the actual EC2 instance.
resource "aws_instance" "tlpi_lab" {
  ami                         = data.aws_ssm_parameter.ubuntu_2404_amd64.value # .value is the AMI ID string we fetched from SSM Parameter Store earlier in the data block
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnets.default.ids[0] # Use the first subnet ID from the returned list we fetched earlier in the data block
  vpc_security_group_ids      = [aws_security_group.tlpi_lab.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_ssm_profile.name
  associate_public_ip_address = true

  instance_market_options {
    market_type = "spot"

    # This means:
      # - spot_instance_type = "one-time"
      # - AWS makes a one-time Spot request for this instance
      # - not persistent
      # - if interrupted, it is not automatically continuously maintained like some other patterns
      # - instance_interruption_behavior = "terminate"
      # - if AWS reclaims the Spot capacity, the instance is terminated
    spot_options {
      spot_instance_type             = "one-time"
      instance_interruption_behavior = "terminate"
    }
  }
  # “Read the file user_data.sh.tftpl, fill in the template variable repo_url, and send the rendered script as EC2 user data.”
  # What user data is: This is a startup script that runs on first boot.
  # Here, it:
    # - installs packages
    # - installs or repairs SSM Agent
    # - creates /home/ubuntu/work
    # - optionally clones your repo
    # - appends shell config to /home/ubuntu/.bashrc
  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    repo_url = var.repo_url
  })

  root_block_device {
    volume_size           = 8
    volume_type           = var.ebs_type
    delete_on_termination = true
  }

  tags = {
    Name = "tlpi-spot-lab"
  }
}

# Outputs:
output "instance_id" {
  value = aws_instance.tlpi_lab.id
}

output "public_ip" {
  value = aws_instance.tlpi_lab.public_ip
}

output "ssm_command" {
  value = "aws ssm start-session --target ${aws_instance.tlpi_lab.id}"
}