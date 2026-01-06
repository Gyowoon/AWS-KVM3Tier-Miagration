#===============================================================================
# security-groups.tf - Security Groups 정의
#===============================================================================
# Phase 1 대응: sg-alb, sg-web, sg-internal-alb, sg-app, sg-db
# 설계 원칙: 최소 권한 원칙 (Tier 간 필요한 포트만 허용)
#
# 트래픽 흐름:
#   Internet → sg-alb(80) → sg-web(80) → sg-internal-alb(8080) 
#           → sg-app(8080) → sg-db(5432)
#===============================================================================

#===============================================================================
# 1. External ALB Security Group
#===============================================================================
# 용도: 인터넷에서 들어오는 HTTP 트래픽 수신
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-sg-alb"
  description = "Security group for external ALB"
  vpc_id      = aws_vpc.main.id

  # Inbound: HTTP from Internet
  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound: 모든 트래픽 허용 (Target으로 전달)
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # 모든 프로토콜
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg-alb"
    Tier = "External-ALB"
  }
}

#===============================================================================
# 2. Web Tier Security Group
#===============================================================================
# 용도: Nginx 서버 (Public Subnet)
resource "aws_security_group" "web" {
  name        = "${var.project_name}-sg-web"
  description = "Security group for Web tier (Nginx)"
  vpc_id      = aws_vpc.main.id

  # Inbound: HTTP from External ALB only
  ingress {
    description     = "HTTP from External ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]  # ALB SG에서만 허용
  }

  # Inbound: SSH from My IP (관리용)
  ingress {
    description = "SSH from My IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]  # 본인 IP만 허용
  }

  # Outbound: 모든 트래픽 허용
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg-web"
    Tier = "Web"
  }
}

#===============================================================================
# 3. Internal ALB Security Group
#===============================================================================
# 용도: Web → App 간 내부 로드밸런싱
resource "aws_security_group" "internal_alb" {
  name        = "${var.project_name}-sg-internal-alb"
  description = "Security group for internal ALB"
  vpc_id      = aws_vpc.main.id

  # Inbound: 8080 from Web Tier only
  ingress {
    description     = "HTTP 8080 from Web tier"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  # Outbound: 모든 트래픽 허용
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg-internal-alb"
    Tier = "Internal-ALB"
  }
}

#===============================================================================
# 4. App Tier Security Group
#===============================================================================
# 용도: WildFly 서버 (Private Subnet)
resource "aws_security_group" "app" {
  name        = "${var.project_name}-sg-app"
  description = "Security group for App tier (WildFly)"
  vpc_id      = aws_vpc.main.id

  # Inbound: 8080 from Internal ALB only
  ingress {
    description     = "HTTP 8080 from Internal ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.internal_alb.id]
  }

  # Inbound: SSH from Web tier (Bastion 역할)
  # Web 서버를 통해 App 서버에 SSH 접속
  ingress {
    description     = "SSH from Web tier (Bastion)"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  # Outbound: 모든 트래픽 허용 (NAT GW 통한 인터넷, RDS 접속)
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg-app"
    Tier = "App"
  }
}

#===============================================================================
# 5. Database Tier Security Group
#===============================================================================
# 용도: RDS PostgreSQL (Private Subnet)
resource "aws_security_group" "db" {
  name        = "${var.project_name}-sg-db"
  description = "Security group for DB tier (RDS)"
  vpc_id      = aws_vpc.main.id

  # Inbound: PostgreSQL from App Tier only
  ingress {
    description     = "PostgreSQL from App tier"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  # Outbound: 기본적으로 불필요하나 AWS 권장사항으로 유지
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg-db"
    Tier = "Database"
  }
}
