terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = " > 4.0"
    }
  }

  backend "s3" {
    bucket         = "terraform-state-626635445388-multiaccount-bucket"
    key            = "626635445388/eu-north-1/data-store/compute/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "terraform-626635445388-data-store-mysql-state-locking"
    encrypt        = true
  }
}

provider "aws" {
  region = "eu-north-1"
  alias = "gt-admin"
}

provider "aws" {
  region = "eu-north-1"
  alias  = "bt26-admin"

  assume_role {
    role_arn = var.bt26_iam_role_arn
  }
}

provider "aws" {
  region = "eu-north-1"
  alias  = "bt27-admin"

  assume_role {
    role_arn = var.bt27_iam_role_arn
  }
}

# locals {
#   user_data = <<-EOT
#     #!/bin/bash
#     sudo bash -c 'echo "Port 1923" >> /etc/ssh/sshd_config' && \
#     sudo systemctl restart sshd && \
#     sudo bash -c "echo 'ssh-ed25519 \
#     AAAAC3NzaC1lZDI1NTE5AAAAIF/t9hUfAgZ9W0q+l8j40juPMaSfEFkgcm+XsMm/dvyJ \
#     ls25@ls25' >> /home/ec2-user/.ssh/authorized_keys"
#   EOT
# }

data "aws_vpc" "default_vpc_bt26" {
  provider = aws.bt26-admin

  default = true
}

data "aws_iam_policy" "dataAccessPolicyLS25BT26" {
  provider = aws.bt26-admin

  name = "dataAccessPolicyLS25"
}

module "ls25-EC2-sg_bt26" {
  source = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  providers = {
    aws = aws.bt26-admin
  }

  name        = "ls25-EC2-sg"
  description = "security group for EC2 instances in the LS25"
  vpc_id      = data.aws_vpc.default_vpc_bt26.id

  ingress_with_cidr_blocks = [
    {
      rule        = "https-443-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      rule        = "http-80-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 1923
      to_port     = 1923
      protocol    = "tcp"
      description = "custom ssh"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  egress_with_cidr_blocks = [
    {
      rule        = "all-all"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

locals {
  multiple_instances = {
    app1 = {
      root_block_device = [
        {
          encrypted   = true
          volume_type = "gp3"
          throughput  = 200
          volume_size = 30
        }
      ]
    }

  #  two = {
  #    instance_type     = "t3.small"
  #    availability_zone = element(module.vpc.azs, 1)
  #    subnet_id         = element(module.vpc.private_subnets, 1)
  #    root_block_device = [
  #      {
  #        encrypted   = true
  #        volume_type = "gp2"
  #        volume_size = 50
  #      }
  #    ]
  #  }

  }
  user_data = <<-EOT
    #!/bin/bash
    sudo bash -c 'echo "Port 1923" >> /etc/ssh/sshd_config' && \
    sudo systemctl restart sshd && \
    sudo bash -c "echo 'ssh-ed25519 \
    AAAAC3NzaC1lZDI1NTE5AAAAIF/t9hUfAgZ9W0q+l8j40juPMaSfEFkgcm+XsMm/dvyJ \
    ls25@ls25' >> /home/ec2-user/.ssh/authorized_keys"
  EOT
}


module "ec2-instance_bt26" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.7.1"

  providers = {
    aws = aws.bt26-admin
  }

  for_each = local.multiple_instances
  name = "instance-${each.key}"
  root_block_device  = lookup(each.value, "root_block_device", [])

  instance_type          = "c7a.medium"
  ami                    = "ami-070fe338fb2265e00" # Amazon Linux 2 AMI (HVM) - Kernel 5.10
  vpc_security_group_ids = [module.ls25-EC2-sg_bt26.security_group_id]
  create_eip             = true

  create_iam_instance_profile = true
  iam_role_description        = "IAM role for EC2 instances"
  iam_role_policies = {
    dataAccessPolicyLS25 = data.aws_iam_policy.dataAccessPolicyLS25BT26.arn
  }

  user_data_base64 = base64encode(local.user_data)

}