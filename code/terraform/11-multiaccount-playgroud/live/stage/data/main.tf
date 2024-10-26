terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }

  backend "s3" {
    bucket         = "terraform-state-626635445388-multiaccount-bucket"
    key            = "626635445388/eu-north-1/data-store/data/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "terraform-626635445388-ls25-state-locking"
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

data "aws_vpc" "default_vpc_bt26" {
  provider = aws.bt26-admin

  default = true
}

module "dynamodb-table-bt26" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "4.2.0"

  providers = {
    aws = aws.bt26-admin
  }

  name                        = "ls25-dynamo-table"
  hash_key                    = "id"
  table_class                 = "STANDARD"
  deletion_protection_enabled = false

  attributes = [
    {
      name = "id"
      type = "N"
    }
  ]
}

module "security_group_postgresql_bt26" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "ls25-postgresql-sg"
  description = "PostgreSQL security group"
  vpc_id      = data.aws_vpc.default_vpc_bt26.id

  providers = {
    aws = aws.bt26-admin
  }

  ingress_with_cidr_blocks = [
    {
      rule        = "postgresql-tcp"
      cidr_blocks = "172.31.0.0/16"
    }
  ]

  egress_with_cidr_blocks = [
    {
      rule        = "all-all"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

module "postgresql-bt26" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.10.0"

  providers = {
    aws = aws.bt26-admin
  }

  identifier = "ls25-rds-postgresql"

  engine                   = "postgres"
  engine_version           = "14"
  engine_lifecycle_support = "open-source-rds-extended-support-disabled"
  family                   = "postgres14" # DB parameter group
  major_engine_version     = "14"         # DB option group
  instance_class           = "db.t3.micro"
  vpc_security_group_ids = [module.security_group_postgresql_bt26.security_group_id]
  allocated_storage     = 20
  max_allocated_storage = 30

  db_name  = "postgres"
  username = "postgres"
  port     = 5432
  multi_az                = false
  deletion_protection     = false

  parameters = [
    {
      name  = "autovacuum"
      value = 1
    },
    {
      name  = "client_encoding"
      value = "utf8"
    }
  ]
}


module "s3_bucket_bt26" {
  source = "terraform-aws-modules/s3-bucket/aws"
  version = "4.2.1"

  providers = {
    aws = aws.bt26-admin
  }

  bucket = "s3-bucket-bt26"
  force_destroy = true
  versioning = {
    enabled = false
  }
}