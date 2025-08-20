# ec2_instances.tf - EC2 Instances Configuration

# Use existing Key Pair
data "aws_key_pair" "existing_key" {
  key_name = var.existing_key_name
}

# Instance A: Frontend (Vote + Result) - Public Subnet
resource "aws_instance" "frontend" {
  ami                         = "ami-0ae2c887094315bed"  # Amazon Linux 2023 - keeping your specified AMI
  instance_type               = var.instance_type
  key_name                    = data.aws_key_pair.existing_key.key_name
  vpc_security_group_ids      = [aws_security_group.frontend_sg.id]
  subnet_id                   = aws_subnet.public_subnet.id
  associate_public_ip_address = true

  user_data = base64encode(templatefile("${path.module}/user_data/install_docker.sh", {
    hostname = "frontend"
  }))

  # Ensure proper root volume
  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
    
    tags = {
      Name = "voting-app-frontend-root"
    }
  }

  tags = {
    Name        = "voting-app-frontend"
    Environment = var.environment
    Project     = "voting-app"
    Tier        = "Frontend"
  }
}

# Instance B: Backend (Redis + Worker) - Private Subnet
resource "aws_instance" "backend" {
  ami                    = "ami-0ae2c887094315bed"  # Amazon Linux 2023 - keeping your specified AMI
  instance_type          = var.instance_type
  key_name               = data.aws_key_pair.existing_key.key_name
  vpc_security_group_ids = [aws_security_group.backend_sg.id]
  subnet_id              = aws_subnet.private_subnet_backend.id

  user_data = base64encode(templatefile("${path.module}/user_data/install_docker.sh", {
    hostname = "backend"
  }))

  # Ensure proper root volume
  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
    
    tags = {
      Name = "voting-app-backend-root"
    }
  }

  tags = {
    Name        = "voting-app-backend"
    Environment = var.environment
    Project     = "voting-app"
    Tier        = "Backend"
  }
}

# Instance C: Database (PostgreSQL) - Private Subnet
resource "aws_instance" "database" {
  ami                    = "ami-0ae2c887094315bed"  # Amazon Linux 2023 - keeping your specified AMI
  instance_type          = var.instance_type
  key_name               = data.aws_key_pair.existing_key.key_name
  vpc_security_group_ids = [aws_security_group.database_sg.id]
  subnet_id              = aws_subnet.private_subnet_database.id

  user_data = base64encode(templatefile("${path.module}/user_data/install_docker.sh", {
    hostname = "database"
  }))

  # Ensure proper root volume with extra space for database
  root_block_device {
    volume_type = "gp3"
    volume_size = 30  # More space for database
    encrypted   = true
    
    tags = {
      Name = "voting-app-database-root"
    }
  }

  tags = {
    Name        = "voting-app-database"
    Environment = var.environment
    Project     = "voting-app"
    Tier        = "Database"
  }
}

# Bastion Host - Public Subnet
resource "aws_instance" "bastion" {
  ami                         = "ami-0ae2c887094315bed"  # Amazon Linux 2023 - keeping your specified AMI
  instance_type               = var.bastion_instance_type
  key_name                    = data.aws_key_pair.existing_key.key_name
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  subnet_id                   = aws_subnet.public_subnet.id
  associate_public_ip_address = true

  user_data = base64encode(templatefile("${path.module}/user_data/configure_bastion.sh", {
    hostname = "bastion"
  }))

  # Small root volume for bastion
  root_block_device {
    volume_type = "gp3"
    volume_size = 10
    encrypted   = true
    
    tags = {
      Name = "voting-app-bastion-root"
    }
  }

  tags = {
    Name        = "voting-app-bastion"
    Environment = var.environment
    Project     = "voting-app"
    Tier        = "Bastion"
  }
}