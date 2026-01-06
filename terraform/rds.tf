#===============================================================================
# rds.tf - RDS Database
#===============================================================================
# Phase 1 대응: portfolio-db (PostgreSQL 16.11)
# 구성:
#   - Engine: PostgreSQL 16
#   - Instance: db.t3.micro (프리티어)
#   - Multi-AZ: No (비용 절감, 프리티어 미지원)
#   - Subnet Group: Private Subnets
#===============================================================================

#---------------------------------------
# DB Subnet Group
#---------------------------------------
# RDS가 배치될 서브넷 그룹 (Private Subnets)
resource "aws_db_subnet_group" "main" {
  name        = "${var.project_name}-db-subnet-group"
  description = "DB subnet group for ${var.project_name}"
  
  # Private Subnets에 배치 (Multi-AZ 지원을 위해 2개 이상 필요)
  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_c.id
  ]

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

#---------------------------------------
# RDS Instance
#---------------------------------------
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-db"

  #-----------------------------------------
  # Engine 설정
  #-----------------------------------------
  engine               = "postgres"
  engine_version       = "16"          # 메이저 버전만 지정 (마이너는 자동)
  instance_class       = var.db_instance_class
  
  #-----------------------------------------
  # 스토리지 설정
  #-----------------------------------------
  allocated_storage     = var.db_allocated_storage  # 20GB
  max_allocated_storage = 100                        # Auto Scaling 최대값
  storage_type          = "gp3"                      # 최신 범용 SSD
  storage_encrypted     = true                       # 암호화 활성화

  #-----------------------------------------
  # 데이터베이스 설정
  #-----------------------------------------
  db_name  = var.db_name      # myappdb
  username = var.db_username  # postgres
  password = var.db_password  # terraform.tfvars에서 지정
  port     = 5432

  #-----------------------------------------
  # 네트워크 설정
  #-----------------------------------------
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false  # Private Subnet, 외부 접근 불가

  #-----------------------------------------
  # 가용성 설정
  #-----------------------------------------
  multi_az = false  # 비용 절감 (프리티어는 Multi-AZ 미지원)
  # 운영 환경에서는 true 권장

  #-----------------------------------------
  # 유지보수 설정
  #-----------------------------------------
  auto_minor_version_upgrade = true  # 마이너 버전 자동 업그레이드
  maintenance_window         = "sun:03:00-sun:04:00"  # 일요일 새벽 (KST 12:00-13:00)

  #-----------------------------------------
  # 백업 설정
  #-----------------------------------------
  backup_retention_period = 7                           # 7일 보관
  backup_window           = "02:00-03:00"              # 새벽 2-3시 (유지보수 전)
  copy_tags_to_snapshot   = true                        # 스냅샷에 태그 복사
  skip_final_snapshot     = true                        # 삭제 시 최종 스냅샷 생략
  # 운영 환경에서는 skip_final_snapshot = false 권장
  # final_snapshot_identifier = "${var.project_name}-db-final"

  #-----------------------------------------
  # 모니터링 설정
  #-----------------------------------------
  # Enhanced Monitoring (선택사항 - IAM Role 필요)
  # monitoring_interval = 60
  # monitoring_role_arn = aws_iam_role.rds_monitoring.arn

  # Performance Insights (프리티어 7일 무료)
  performance_insights_enabled          = true
  performance_insights_retention_period = 7

  #-----------------------------------------
  # 파라미터 그룹 (선택사항)
  #-----------------------------------------
  # 기본 파라미터 그룹 사용
  # parameter_group_name = aws_db_parameter_group.main.name

  #-----------------------------------------
  # 삭제 보호
  #-----------------------------------------
  deletion_protection = false  # 개발 환경에서는 false
  # 운영 환경에서는 true 권장

  tags = {
    Name = "${var.project_name}-db"
    Tier = "Database"
  }
}
