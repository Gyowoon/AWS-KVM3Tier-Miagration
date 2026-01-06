#===============================================================================
# variables.tf - 입력 변수 정의
#===============================================================================
# 역할: 재사용 가능한 변수 선언 (실제 값은 terraform.tfvars에서 설정)
# 설계 원칙: 환경별로 다를 수 있는 값은 모두 변수화
#===============================================================================

#---------------------------------------
# 기본 설정 변수
#---------------------------------------
variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"  # 서울 리전
}

variable "aws_profile" {
  description = "AWS CLI 프로파일명 (~/.aws/credentials)"
  type        = string
  default     = "terraform-admin"
}

variable "project_name" {
  description = "프로젝트 이름 (리소스 명명에 사용)"
  type        = string
  default     = "portfolio"
}

variable "environment" {
  description = "환경 구분 (dev/staging/prod)"
  type        = string
  default     = "dev"
}

#---------------------------------------
# 네트워크 변수
#---------------------------------------
variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
  default     = "10.0.0.0/16"
}

# 서브넷 CIDR 맵 (AZ별로 Public/Private 구분)
variable "subnet_cidrs" {
  description = "서브넷 CIDR 블록 맵"
  type        = map(string)
  default = {
    public_a  = "10.0.1.0/24"  # Web Tier - AZ a
    private_a = "10.0.2.0/24"  # App Tier - AZ a
    public_c  = "10.0.3.0/24"  # Web Tier - AZ c
    private_c = "10.0.4.0/24"  # App Tier - AZ c
  }
}

# 가용영역 설정
variable "availability_zones" {
  description = "사용할 가용영역 목록"
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2c"]
}

#---------------------------------------
# EC2 변수
#---------------------------------------
variable "ec2_instance_type" {
  description = "EC2 인스턴스 타입"
  type        = string
  default     = "t3.small"  
  # 프리티어 호환, 해당 AMI에서 사용 가능하도록 micro에서 small로 변경
}

variable "ec2_key_name" {
  description = "EC2 SSH 키페어 이름 (AWS에 등록된 키)"
  type        = string
  # 기본값 없음 - terraform.tfvars에서 필수 지정
}

variable "my_ip" {
  description = "SSH 접속 허용 IP (CIDR 형식: x.x.x.x/32)"
  type        = string
  # 보안상 기본값 없음 - terraform.tfvars에서 지정
}

#---------------------------------------
# RDS 변수
#---------------------------------------
variable "db_instance_class" {
  description = "RDS 인스턴스 클래스"
  type        = string
  default     = "db.t3.micro"  # 프리티어 호환
}

variable "db_name" {
  description = "데이터베이스 이름"
  type        = string
  default     = "myappdb"
}

variable "db_username" {
  description = "DB 마스터 사용자명"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "DB 마스터 비밀번호"
  type        = string
  sensitive   = true  # 출력 시 마스킹 처리
  # 기본값 없음 - terraform.tfvars 또는 환경변수로 지정
}

variable "db_allocated_storage" {
  description = "RDS 스토리지 크기 (GB)"
  type        = number
  default     = 20  # 프리티어 최대
}

#---------------------------------------
# ALB 변수
#---------------------------------------
variable "health_check_path" {
  description = "ALB 헬스체크 경로"
  type        = string
  default     = "/"
}

#---------------------------------------
# 태그 변수
#---------------------------------------
variable "common_tags" {
  description = "모든 리소스에 적용할 추가 태그"
  type        = map(string)
  default     = {}
}


