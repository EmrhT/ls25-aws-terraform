terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    bucket         = "terraform-state-626635445388-multiaccount-bucket"
    key            = "626635445388/eu-north-1/data-store/data/terraform.tfstate"
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

module "mysql_bt26" {

  providers = {
    aws = aws.bt26-admin
  }

  source = "../../../../modules/data-stores/mysql"

  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password
}

module "mysql_bt27" {

  providers = {
    aws = aws.bt27-admin
  }

  source = "../../../../modules/data-stores/mysql"

  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password
}
