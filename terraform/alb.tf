#===============================================================================
# alb.tf - Application Load Balancers
#===============================================================================
# Phase 1 대응: portfolio-alb (External), portfolio-internal-alb (Internal)
# 아키텍처:
#   Internet → External ALB (port 80) → Web EC2 (port 80)
#   Web EC2 → Internal ALB (port 8080) → App EC2 (port 8080)
#===============================================================================

#===============================================================================
# External ALB (Internet-facing)
#===============================================================================
# 용도: 인터넷에서 들어오는 트래픽을 Web Tier로 분산

#---------------------------------------
# External ALB
#---------------------------------------
resource "aws_lb" "external" {
  name               = "${var.project_name}-alb"
  internal           = false  # Internet-facing
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  
  # Multi-AZ 배치 (Public Subnets)
  subnets = [
    aws_subnet.public_a.id,
    aws_subnet.public_c.id
  ]

  # 삭제 보호 (운영 환경에서는 true 권장)
  enable_deletion_protection = false

  # 액세스 로그 (선택사항 - S3 버킷 필요)
  # access_logs {
  #   bucket  = aws_s3_bucket.alb_logs.bucket
  #   prefix  = "external-alb"
  #   enabled = true
  # }

  tags = {
    Name = "${var.project_name}-alb"
    Type = "External"
  }
}

#---------------------------------------
# External ALB Target Group
#---------------------------------------
# Web Tier EC2를 타겟으로 등록
resource "aws_lb_target_group" "web" {
  name        = "${var.project_name}-tg-web"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  # 헬스체크 설정
  health_check {
    enabled             = true
    healthy_threshold   = 2      # 2번 연속 성공 시 Healthy
    unhealthy_threshold = 2      # 2번 연속 실패 시 Unhealthy
    timeout             = 5      # 5초 내 응답 필요
    interval            = 30     # 30초마다 체크
    path                = var.health_check_path
    protocol            = "HTTP"
    matcher             = "200"  # HTTP 200 응답만 성공
  }

  # 연결 드레이닝 (Graceful shutdown)
  deregistration_delay = 30  # 30초 대기 후 연결 종료

  tags = {
    Name = "${var.project_name}-tg-web"
  }
}

#---------------------------------------
# Web Targets 등록
#---------------------------------------
resource "aws_lb_target_group_attachment" "web_a" {
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.web_a.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "web_c" {
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.web_c.id
  port             = 80
}

#---------------------------------------
# External ALB Listener
#---------------------------------------
resource "aws_lb_listener" "external_http" {
  load_balancer_arn = aws_lb.external.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }

  tags = {
    Name = "${var.project_name}-listener-http"
  }
}

#===============================================================================
# Internal ALB
#===============================================================================
# 용도: Web Tier에서 App Tier로 트래픽 분산

#---------------------------------------
# Internal ALB
#---------------------------------------
resource "aws_lb" "internal" {
  name               = "${var.project_name}-internal-alb"
  internal           = true  # Internal (VPC 내부에서만 접근)
  load_balancer_type = "application"
  security_groups    = [aws_security_group.internal_alb.id]
  
  # Multi-AZ 배치 (Private Subnets)
  subnets = [
    aws_subnet.private_a.id,
    aws_subnet.private_c.id
  ]

  enable_deletion_protection = false

  tags = {
    Name = "${var.project_name}-internal-alb"
    Type = "Internal"
  }
}

#---------------------------------------
# Internal ALB Target Group
#---------------------------------------
# App Tier EC2를 타겟으로 등록
resource "aws_lb_target_group" "app" {
  name        = "${var.project_name}-tg-app"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"       # WildFly 기본 페이지
    port                = "8080"
    protocol            = "HTTP"
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = {
    Name = "${var.project_name}-tg-app"
  }
}

#---------------------------------------
# App Targets 등록
#---------------------------------------
resource "aws_lb_target_group_attachment" "app_a" {
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.app_a.id
  port             = 8080
}

resource "aws_lb_target_group_attachment" "app_c" {
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.app_c.id
  port             = 8080
}

#---------------------------------------
# Internal ALB Listener
#---------------------------------------
resource "aws_lb_listener" "internal_http" {
  load_balancer_arn = aws_lb.internal.arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  tags = {
    Name = "${var.project_name}-listener-internal"
  }
}
