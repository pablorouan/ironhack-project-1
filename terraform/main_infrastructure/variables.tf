# variables.tf - Variables Configuration

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-northeast-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_backend_cidr" {
  description = "CIDR block for private backend subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_subnet_database_cidr" {
  description = "CIDR block for private database subnet"
  type        = string
  default     = "10.0.3.0/24"
}

variable "instance_type" {
  description = "EC2 instance type for application servers"
  type        = string
  default     = "t3.micro"
}

variable "bastion_instance_type" {
  description = "EC2 instance type for bastion host"
  type        = string
  default     = "t3.nano"
}

variable "existing_key_name" {
  description = "Name of the existing AWS key pair"
  type        = string
  default     = "pablo-voting-app-key"
}

variable "private_key_path" {
  description = "Path to the private key file (.pem extension for AWS keys)"
  type        = string
  default     = "~/.ssh/pablo-voting-app-key.pem"
}

variable "public_key_path" {
  description = "Path to the public key file (not needed when using existing key, but kept for reference)"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "your_ip_cidr" {
  description = "Your public IP address in CIDR notation (for SSH access to bastion)"
  type        = string
  default     = "95.91.214.19/32"
  # You need to set this to your actual public IP, e.g., "203.0.113.12/32"
  # You can find your IP with: curl ifconfig.me
}
# Add to variables.tf

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "pablorouan.com"
}

variable "create_alb" {
  description = "Whether to create ALB and Route 53 records"
  type        = bool
  default     = true
}