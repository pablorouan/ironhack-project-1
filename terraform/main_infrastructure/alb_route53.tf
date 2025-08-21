# alb_route53.tf - Application Load Balancer with Route 53 for Path-Based Routing

# Security Group for ALB
resource "aws_security_group" "alb_sg" {
  name_prefix = "voting-app-alb-"
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

  # All outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "voting-app-alb-sg"
    Environment = var.environment
    Project     = "voting-app"
  }
}

# Application Load Balancer
resource "aws_lb" "voting_app_alb" {
  name               = "voting-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets           = [aws_subnet.public_subnet.id, aws_subnet.public_subnet_2.id]  # Two AZs required for ALB

  enable_deletion_protection = false

  tags = {
    Name        = "voting-app-alb"
    Environment = var.environment
    Project     = "voting-app"
  }
}

# Target Group for Vote App
resource "aws_lb_target_group" "vote_tg" {
  name     = "vote-app-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.voting_app_vpc.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "vote-app-tg"
    Environment = var.environment
    Project     = "voting-app"
  }
}

# Target Group for Result App
resource "aws_lb_target_group" "result_tg" {
  name     = "result-app-tg"
  port     = 8081
  protocol = "HTTP"
  vpc_id   = aws_vpc.voting_app_vpc.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "result-app-tg"
    Environment = var.environment
    Project     = "voting-app"
  }
}

# Target Group Attachments
resource "aws_lb_target_group_attachment" "vote_attachment" {
  target_group_arn = aws_lb_target_group.vote_tg.arn
  target_id        = aws_instance.frontend.id
  port             = 8080
}

resource "aws_lb_target_group_attachment" "result_attachment" {
  target_group_arn = aws_lb_target_group.result_tg.arn
  target_id        = aws_instance.frontend.id
  port             = 8081
}

# ALB Listener
resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.voting_app_alb.arn
  port              = "80"
  protocol          = "HTTP"

  # Default action - redirect to vote
  default_action {
    type = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.vote_tg.arn
      }
    }
  }
}

# Listener Rules for Path-Based Routing
resource "aws_lb_listener_rule" "vote_rule" {
  listener_arn = aws_lb_listener.web.arn
  priority     = 100

  action {
    type = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.vote_tg.arn
      }
    }
  }

  condition {
    path_pattern {
      values = ["/vote*"]
    }
  }
}

resource "aws_lb_listener_rule" "result_rule" {
  listener_arn = aws_lb_listener.web.arn
  priority     = 200

  action {
    type = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.result_tg.arn
      }
    }
  }

  condition {
    path_pattern {
      values = ["/result*"]
    }
  }
}

# Route 53 Records
data "aws_route53_zone" "main" {
  name         = "pablorouan.com"
  private_zone = false
}

# Main domain pointing to ALB
resource "aws_route53_record" "main" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "pablorouan.com"
  type    = "A"

  alias {
    name                   = aws_lb.voting_app_alb.dns_name
    zone_id               = aws_lb.voting_app_alb.zone_id
    evaluate_target_health = true
  }
}

# Optional: www subdomain
resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "www.pablorouan.com"
  type    = "A"

  alias {
    name                   = aws_lb.voting_app_alb.dns_name
    zone_id               = aws_lb.voting_app_alb.zone_id
    evaluate_target_health = true
  }
}

# Outputs
output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.voting_app_alb.dns_name
}

output "voting_app_urls" {
  description = "Application URLs"
  value = {
    vote_direct   = "http://${aws_lb.voting_app_alb.dns_name}/vote"
    result_direct = "http://${aws_lb.voting_app_alb.dns_name}/result"
    vote_custom   = "https://pablorouan.com/vote"      # HTTPS!
    result_custom = "https://pablorouan.com/result"    # HTTPS!
    vote_custom_alt   = "https://www.pablorouan.com/vote"
    result_custom_alt = "https://www.pablorouan.com/result"
  }
}# Add to alb_route53.tf - SSL Certificate Configuration

# Request SSL Certificate from ACM
resource "aws_acm_certificate" "main" {
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]  # Wildcard for subdomains
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "voting-app-ssl-cert"
    Environment = var.environment
    Project     = "voting-app"
  }
}

# DNS validation records
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
}

# Certificate validation
resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]

  timeouts {
    create = "5m"
  }
}

# HTTPS Listener for ALB
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.voting_app_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate_validation.main.certificate_arn

  # Default action - forward to vote
  default_action {
    type = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.vote_tg.arn
      }
    }
  }
}

# HTTPS Listener Rules
resource "aws_lb_listener_rule" "vote_rule_https" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.vote_tg.arn
      }
    }
  }

  condition {
    path_pattern {
      values = ["/vote*"]
    }
  }
}

resource "aws_lb_listener_rule" "result_rule_https" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 200

  action {
    type = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.result_tg.arn
      }
    }
  }

  condition {
    path_pattern {
      values = ["/result*"]
    }
  }
}

# HTTP to HTTPS Redirect
resource "aws_lb_listener_rule" "redirect_http_to_https" {
  listener_arn = aws_lb_listener.web.arn
  priority     = 1

  action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  condition {
    host_header {
      values = [var.domain_name, "www.${var.domain_name}"]
    }
  }
}