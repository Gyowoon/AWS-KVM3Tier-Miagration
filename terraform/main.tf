#===============================================================================
# main.tf - Terraform 기본 설정
#===============================================================================
# 역할: AWS Provider 설정 및 Terraform 버전 요구사항 정의
# Phase 1 대응: AWS CLI 프로파일 설정 (terraform-admin 사용자)
#===============================================================================

#---------------------------------------
# Terraform 버전 및 Provider 요구사항
#---------------------------------------
terraform {
  # Terraform 최소 버전 (1.0 이상 권장)
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  # 5.x 버전대 사용 (최신 기능 지원)
    }
  }

  #-----------------------------------------
  # Backend 설정 (선택사항)
  #-----------------------------------------
  # 실무에서는 S3 Backend를 사용하여 State 파일을 원격 저장
  # 개인 프로젝트에서는 local backend (기본값) 사용
  #
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "aws-3tier/terraform.tfstate"
  #   region         = "ap-northeast-2"
  #   encrypt        = true
  #   dynamodb_table = "terraform-lock"  # State Locking용
  # }
}

#---------------------------------------
# AWS Provider 설정
#---------------------------------------
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile  # ~/.aws/credentials의 프로파일명

  # 모든 리소스에 기본 태그 적용 (Terraform 5.x 기능)
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "Gu"
    }
  }
}

#---------------------------------------
# 현재 AWS 계정 정보 조회
#---------------------------------------
# 용도: ARN 구성, 계정 ID 참조 등에 활용
data "aws_caller_identity" "current" {}

# 현재 리전 정보
data "aws_region" "current" {}
