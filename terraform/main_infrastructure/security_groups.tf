# security_groups.tf - Security Groups Configuration

# Security Group for Bastion Host
resource "aws_security_group" "bastion_sg" {
  name_prefix = "voting-app-bastion-"
  vpc_id      = aws_vpc.voting_app_vpc.id

  # SSH access from your IP (you'll need to replace with your actual IP)
  ingress {
    description = "SSH from your IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.your_ip_cidr]  # Define this in variables
  }

  # All outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "voting-app-bastion-sg"
    Environment = var.environment
    Project     = "voting-app"
  }
}

# Security Group for Frontend (Vote/Result)
resource "aws_security_group" "frontend_sg" {
  name_prefix = "voting-app-frontend-"
  vpc_id      = aws_vpc.voting_app_vpc.id

  # HTTP access from internet
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access from internet
  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Custom ports for Vote (8080) and Result (8081) apps
  ingress {
    description = "Vote app port"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Result app port"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH from Bastion
  ingress {
    description     = "SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  # All outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "voting-app-frontend-sg"
    Environment = var.environment
    Project     = "voting-app"
  }
}

# Security Group for Backend (Redis/Worker)
resource "aws_security_group" "backend_sg" {
  name_prefix = "voting-app-backend-"
  vpc_id      = aws_vpc.voting_app_vpc.id

  # Redis port from Frontend
  ingress {
    description     = "Redis from Frontend"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_sg.id]
  }

  # SSH from Bastion
  ingress {
    description     = "SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  # All outbound traffic (needed for Worker to connect to Postgres and for package downloads)
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "voting-app-backend-sg"
    Environment = var.environment
    Project     = "voting-app"
  }
}

# Security Group for Database (PostgreSQL)
resource "aws_security_group" "database_sg" {
  name_prefix = "voting-app-database-"
  vpc_id      = aws_vpc.voting_app_vpc.id

  # PostgreSQL port from Backend (Worker)
  ingress {
    description     = "PostgreSQL from Backend"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_sg.id]
  }

  # PostgreSQL port from Frontend (Result app needs direct DB access)
  ingress {
    description     = "PostgreSQL from Frontend"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_sg.id]
  }

  # SSH from Bastion
  ingress {
    description     = "SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  # All outbound traffic (needed for package downloads)
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "voting-app-database-sg"
    Environment = var.environment
    Project     = "voting-app"
  }
}

# Add to security_groups.tf - Frontend SG updates

# Add this ingress rule to the existing frontend security group
resource "aws_security_group_rule" "frontend_from_alb_8080" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_sg.id
  security_group_id        = aws_security_group.frontend_sg.id
  description              = "Vote app from ALB"
}

resource "aws_security_group_rule" "frontend_from_alb_8081" {
  type                     = "ingress"
  from_port                = 8081
  to_port                  = 8081
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_sg.id
  security_group_id        = aws_security_group.frontend_sg.id
  description              = "Result app from ALB"
  }