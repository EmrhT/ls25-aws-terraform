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
    key            = "626635445388/eu-north-1/data-store/iam/terraform.tfstate"
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

module "iam_policy_bt26" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.47.1"

  providers = {
    aws = aws.bt26-admin
  }

  name = "dataAccessPolicyLS25"

  create_policy = true

  policy = <<EOF
{ 
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "DynamoDBTableAccess",
            "Effect": "Allow",
            "Action": [
                "dynamodb:BatchGetItem",
                "dynamodb:BatchWriteItem",
                "dynamodb:ConditionCheckItem",
                "dynamodb:PutItem",
                "dynamodb:DescribeTable",
                "dynamodb:DeleteItem",
                "dynamodb:GetItem",
                "dynamodb:Scan",
                "dynamodb:Query",
                "dynamodb:UpdateItem"
            ],
          "Resource": "arn:aws:dynamodb:eu-north-1:061051260191:table/*"
        },
    {
      "Sid":"ReadWriteS3",
      "Action": ["s3:ListBucket"],
      "Effect": "Allow",
      "Resource": ["arn:aws:s3:::*"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:GetObjectTagging",
        "s3:DeleteObject",              
        "s3:DeleteObjectVersion",
        "s3:GetObjectVersion",
        "s3:GetObjectVersionTagging",
        "s3:GetObjectACL",
        "s3:PutObjectACL"
      ],
      "Resource": ["arn:aws:s3:::*"]
    },
      {
        "Sid": "RDSDataServiceAccess",
        "Effect": "Allow",
        "Action": [
            "dbqms:CreateFavoriteQuery",
            "dbqms:DescribeFavoriteQueries",
            "dbqms:UpdateFavoriteQuery",
            "dbqms:DeleteFavoriteQueries",
            "dbqms:GetQueryString",
            "dbqms:CreateQueryHistory",
            "dbqms:DescribeQueryHistory",
            "dbqms:UpdateQueryHistory",
            "dbqms:DeleteQueryHistory",
            "rds-data:ExecuteSql",
            "rds-data:ExecuteStatement",
            "rds-data:BatchExecuteStatement",
            "rds-data:BeginTransaction",
            "rds-data:CommitTransaction",
            "rds-data:RollbackTransaction",
            "tag:GetResources"
        ],
        "Resource": "*"
      }
    ]
  }
EOF
}

module "iam_assumable_role_bt26" {

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.47.1"

  providers = {
    aws = aws.bt26-admin
  }

  allow_self_assume_role = false

  trusted_role_services = [
    "ec2.amazonaws.com"
  ]

  custom_role_policy_arns = [
    module.iam_policy_bt26.arn
  ]

  role_name         = "dataAccessRoleforEC2LS25"

  create_role             = true
  create_instance_profile = true
  role_requires_mfa = false
  attach_admin_policy = false

}