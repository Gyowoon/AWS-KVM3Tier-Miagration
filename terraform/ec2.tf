#===============================================================================
# ec2.tf - EC2 Instances
#===============================================================================
# Phase 1 대응: portfolio-web-a/c, portfolio-app-a/c
# 구성:
#   - Web Tier: Rocky Linux 9 + Nginx (Public Subnet, 2대)
#   - App Tier: Rocky Linux 9 + WildFly 31 (Private Subnet, 2대)
#
# 참고: 소프트웨어 설치는 Ansible로 처리 (Phase 2.2)
#       여기서는 EC2 인스턴스 생성만 담당
#===============================================================================

#===============================================================================
# AMI Data Source
#===============================================================================
# Rocky Linux 9 공식 AMI 조회 -> Hardcoding된 AMI ID 사용
# AWS Marketplace의 Rocky Linux 9 (Community Edition)

locals {
  rocky9_ami_id = "ami-04cb94d36182895f6"
}

#===============================================================================
# Web Tier EC2 Instances
#===============================================================================
# 용도: Nginx 리버스 프록시 (Public Subnet)
# Ansible로 Nginx 설치 및 설정 예정

#---------------------------------------
# Web Server A (AZ-a)
#---------------------------------------
resource "aws_instance" "web_a" {
  ami                    = local.rocky9_ami_id
  instance_type          = var.ec2_instance_type
  key_name               = var.ec2_key_name
  subnet_id              = aws_subnet.public_a.id
  vpc_security_group_ids = [aws_security_group.web.id]

  # 퍼블릭 IP 자동 할당 (subnet 설정과 별개로 명시)
  associate_public_ip_address = true

  # 루트 볼륨 설정
  root_block_device {
    volume_type           = "gp3"      # 최신 범용 SSD
    volume_size           = 10         # 10GB (프리티어)
    delete_on_termination = true       # 인스턴스 삭제 시 볼륨도 삭제
    encrypted             = true       # 암호화 활성화 (보안 강화)
  }

  # IMDSv2 강제 (보안 Best Practice)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"  # IMDSv2만 허용
    http_put_response_hop_limit = 1
  }

  tags = {
    Name = "${var.project_name}-web-a"
    Tier = "Web"
    AZ   = var.availability_zones[0]
  }
}

#---------------------------------------
# Web Server C (AZ-c)
#---------------------------------------
resource "aws_instance" "web_c" {
  ami                    = local.rocky9_ami_id
  instance_type          = var.ec2_instance_type
  key_name               = var.ec2_key_name
  subnet_id              = aws_subnet.public_c.id
  vpc_security_group_ids = [aws_security_group.web.id]

  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 10
    delete_on_termination = true
    encrypted             = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = {
    Name = "${var.project_name}-web-c"
    Tier = "Web"
    AZ   = var.availability_zones[1]
  }
}

#===============================================================================
# App Tier EC2 Instances
#===============================================================================
# 용도: WildFly 애플리케이션 서버 (Private Subnet)
# Ansible로 Java 17 + WildFly 31 설치 예정

#---------------------------------------
# App Server A (AZ-a)
#---------------------------------------
resource "aws_instance" "app_a" {
  ami                    = local.rocky9_ami_id
  instance_type          = var.ec2_instance_type
  key_name               = var.ec2_key_name
  subnet_id              = aws_subnet.private_a.id
  vpc_security_group_ids = [aws_security_group.app.id]

  # Private Subnet이므로 퍼블릭 IP 불필요
  associate_public_ip_address = false

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 10
    delete_on_termination = true
    encrypted             = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = {
    Name = "${var.project_name}-app-a"
    Tier = "App"
    AZ   = var.availability_zones[0]
  }
}

#---------------------------------------
# App Server C (AZ-c)
#---------------------------------------
resource "aws_instance" "app_c" {
  ami                    = local.rocky9_ami_id
  instance_type          = var.ec2_instance_type
  key_name               = var.ec2_key_name
  subnet_id              = aws_subnet.private_c.id
  vpc_security_group_ids = [aws_security_group.app.id]

  associate_public_ip_address = false

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 10
    delete_on_termination = true
    encrypted             = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = {
    Name = "${var.project_name}-app-c"
    Tier = "App"
    AZ   = var.availability_zones[1]
  }
}
