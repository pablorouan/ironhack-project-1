# ec2_instances.tf - EC2 Instances Configuration

# Use existing Key Pair
data "aws_key_pair" "existing_key" {
  key_name = "pablo-voting-app-key"
}

# Instance A: Frontend (Vote + Result) - Public Subnet
resource "aws_instance" "frontend" {
  ami                         = "ami-0ae2c887094315bed"
  instance_type               = var.instance_type
  key_name                    = data.aws_key_pair.existing_key.key_name
  vpc_security_group_ids      = [aws_security_group.frontend_sg.id]
  subnet_id                   = aws_subnet.public_subnet.id
  associate_public_ip_address = true

  user_data = base64encode(templatefile("${path.module}/user_data/install_docker.sh", {
    hostname = "frontend"
  }))

  tags = {
    Name        = "voting-app-frontend"
    Environment = var.environment
    Project     = "voting-app"
    Tier        = "Frontend"
  }
}

# Instance B: Backend (Redis + Worker) - Private Subnet
resource "aws_instance" "backend" {
  ami                    = "ami-0ae2c887094315bed"
  instance_type          = var.instance_type
  key_name               = data.aws_key_pair.existing_key.key_name
  vpc_security_group_ids = [aws_security_group.backend_sg.id]
  subnet_id              = aws_subnet.private_subnet_backend.id

  user_data = base64encode(templatefile("${path.module}/user_data/install_docker.sh", {
    hostname = "backend"
  }))

  tags = {
    Name        = "voting-app-backend"
    Environment = var.environment
    Project     = "voting-app"
    Tier        = "Backend"
  }
}

# Instance C: Database (PostgreSQL) - Private Subnet
resource "aws_instance" "database" {
  ami                    = "ami-0ae2c887094315bed"
  instance_type          = var.instance_type
  key_name               = data.aws_key_pair.existing_key.key_name
  vpc_security_group_ids = [aws_security_group.database_sg.id]
  subnet_id              = aws_subnet.private_subnet_database.id

  user_data = base64encode(templatefile("${path.module}/user_data/install_docker.sh", {
    hostname = "database"
  }))

  tags = {
    Name        = "voting-app-database"
    Environment = var.environment
    Project     = "voting-app"
    Tier        = "Database"
  }
}

# EBS Volume for PostgreSQL Data Persistence
resource "aws_ebs_volume" "postgres_data" {
  availability_zone = aws_instance.database.availability_zone
  size             = 20
  type             = "gp3"
  encrypted        = true

  tags = {
    Name        = "postgres-data-volume"
    Environment = var.environment
    Project     = "voting-app"
    Purpose     = "PostgreSQL Data Storage"
  }
}

# Attach the volume to the database instance
resource "aws_volume_attachment" "postgres_attachment" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.postgres_data.id
  instance_id = aws_instance.database.id
}

# Bastion Host - Public Subnet
resource "aws_instance" "bastion" {
  ami                         = "ami-0ae2c887094315bed"
  instance_type               = var.bastion_instance_type
  key_name                    = data.aws_key_pair.existing_key.key_name
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  subnet_id                   = aws_subnet.public_subnet.id
  associate_public_ip_address = true

  user_data = base64encode(templatefile("${path.module}/user_data/configure_bastion.sh", {
    hostname = "bastion"
  }))

  tags = {
    Name        = "voting-app-bastion"
    Environment = var.environment
    Project     = "voting-app"
    Tier        = "Bastion"
  }
}
