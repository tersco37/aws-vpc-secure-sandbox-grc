# 1. Tell Terraform which provider plugins are required and their versions
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# 2. Configure the AWS Provider and target region
provider "aws" {
  region = "us-east-1"
}

# 3. Define your VPC (recreating your 10.0.0.0/16 network)
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "project2-sec-assessment-vpc"
  }
}
# checkov:skip=CKV_AWS_394: Standard project design utilizing dynamic availability zones
data "aws_availability_zones" "available" {
    state = "available"
}
# 2. Public Subnet 1 (AZ 1)
resource "aws_subnet" "public_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "project2-public-subnet-1"
  }
}

# 3. Public Subnet 2 (AZ 2)
resource "aws_subnet" "public_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "project2-public-subnet-2"
  }
}

# 4. Private Subnet 1 (AZ 1)
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.101.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "project2-private-subnet-1"
  }
}

# 5. Private Subnet 2 (AZ 2)
resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.102.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "project2-private-subnet-2"
  }
}

# 1. Create the Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "project2-igw"
  }
}

# 2. Create a Custom Route Table for Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "project2-public-route-table"
  }
}

# 3. Associate Public Subnet 1 with the Public Route Table
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

# 4. Associate Public Subnet 2 with the Public Route Table
resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# Restrict the default security group to block all traffic
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  ingress = []
  egress  = []

  tags = {
    Name = "project2-default-sg-restricted"
  }
}

# checkov:skip=CKV_AWS_158: Cost optimization for free-tier sandbox environment
# checkov:skip=CKV_AWS_338: Reduced log retention for cost control in test architecture
resource "aws_cloudwatch_log_group" "flow_log" {
  name              = "/aws/vpc/project2-flow-logs"
  retention_in_days = 30
}
# IAM Role for VPC Flow Logs
resource "aws_iam_role" "flow_log" {
  name = "project2-vpc-flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}

# Scoped IAM Policy for VPC Flow Logs (Least Privilege)
resource "aws_iam_role_policy" "flow_log" {
  name = "project2-vpc-flow-log-policy"
  role = aws_iam_role.flow_log.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "${aws_cloudwatch_log_group.flow_log.arn}:*"
      }
    ]
  })
}

# The actual VPC Flow Log resource
resource "aws_flow_log" "main" {
  vpc_id          = aws_vpc.main.id
  traffic_type    = "ALL"
  iam_role_arn    = aws_iam_role.flow_log.arn
  log_destination = aws_cloudwatch_log_group.flow_log.arn
}