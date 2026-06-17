provider "aws" {
  region = var.aws_region
}

# CloudFront ACM
provider "aws" {
  alias = "us_east_1"
  region = "us-east-1"
}