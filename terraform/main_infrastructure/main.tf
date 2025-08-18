# main.tf - Main Terraform Configuration

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Remote state backend configuration
  backend "s3" {
    bucket         = "voting-app-bucket-pablo"                 # Set to own unique S3 Bucket name
    key            = "voting-app/terraform.tfstate"
    region         = "ap-northeast-2"                          # Set to be Seoul
    dynamodb_table = "voting-app-dynamodb-pablo"               # Set to own dynamoDB table
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

# Data source to get availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Data source to get the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Create VPC
resource "aws_vpc" "voting_app_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "voting-app-vpc"
    Environment = var.environment
    Project     = "voting-app"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "voting_app_igw" {
  vpc_id = aws_vpc.voting_app_vpc.id

  tags = {
    Name        = "voting-app-igw"
    Environment = var.environment
    Project     = "voting-app"
  }
}

# Create Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.voting_app_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name        = "voting-app-public-subnet"
    Environment = var.environment
    Project     = "voting-app"
    Type        = "Public"
  }
}

# Create Private Subnet for Backend Services
resource "aws_subnet" "private_subnet_backend" {
  vpc_id            = aws_vpc.voting_app_vpc.id
  cidr_block        = var.private_subnet_backend_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name        = "voting-app-private-backend-subnet"
    Environment = var.environment
    Project     = "voting-app"
    Type        = "Private-Backend"
  }
}

# Create Private Subnet for Database
resource "aws_subnet" "private_subnet_database" {
  vpc_id            = aws_vpc.voting_app_vpc.id
  cidr_block        = var.private_subnet_database_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name        = "voting-app-private-database-subnet"
    Environment = var.environment
    Project     = "voting-app"
    Type        = "Private-Database"
  }
}

# Create NAT Gateway EIP
resource "aws_eip" "nat_gateway_eip" {
  domain = "vpc"
  
  depends_on = [aws_internet_gateway.voting_app_igw]

  tags = {
    Name        = "voting-app-nat-eip"
    Environment = var.environment
    Project     = "voting-app"
  }
}

# Create NAT Gateway
resource "aws_nat_gateway" "voting_app_nat" {
  allocation_id = aws_eip.nat_gateway_eip.id
  subnet_id     = aws_subnet.public_subnet.id

  depends_on = [aws_internet_gateway.voting_app_igw]

  tags = {
    Name        = "voting-app-nat-gateway"
    Environment = var.environment
    Project     = "voting-app"
  }
}

# Create Route Table for Public Subnet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.voting_app_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.voting_app_igw.id
  }

  tags = {
    Name        = "voting-app-public-rt"
    Environment = var.environment
    Project     = "voting-app"
  }
}

# Create Route Table for Private Subnets
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.voting_app_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.voting_app_nat.id
  }

  tags = {
    Name        = "voting-app-private-rt"
    Environment = var.environment
    Project     = "voting-app"
  }
}

# Associate Route Table with Public Subnet
resource "aws_route_table_association" "public_rta" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Associate Route Table with Private Backend Subnet
resource "aws_route_table_association" "private_backend_rta" {
  subnet_id      = aws_subnet.private_subnet_backend.id
  route_table_id = aws_route_table.private_rt.id
}

# Associate Route Table with Private Database Subnet
resource "aws_route_table_association" "private_database_rta" {
  subnet_id      = aws_subnet.private_subnet_database.id
  route_table_id = aws_route_table.private_rt.id
}