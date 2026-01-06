#===============================================================================
# vpc.tf - VPC 및 네트워크 리소스
#===============================================================================
# Phase 1 대응: portfolio-vpc, 4개 서브넷, IGW, NAT GW, Route Tables
# 아키텍처:
#   - Public Subnets (2개): Web Tier + NAT Gateway + ALB
#   - Private Subnets (2개): App Tier + RDS
#===============================================================================

#---------------------------------------
# VPC
#---------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true  # DNS 호스트네임 활성화 (RDS 접속에 필요)
  enable_dns_support   = true  # DNS 해석 활성화

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

#---------------------------------------
# Internet Gateway
#---------------------------------------
# 용도: Public Subnet의 인터넷 연결
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

#===============================================================================
# Subnets
#===============================================================================

#---------------------------------------
# Public Subnet A (AZ-a) - Web Tier
#---------------------------------------
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidrs["public_a"]
  availability_zone       = var.availability_zones[0]  # ap-northeast-2a
  map_public_ip_on_launch = true  # 인스턴스에 퍼블릭 IP 자동 할당

  tags = {
    Name = "${var.project_name}-pub-a"
    Tier = "Public"
  }
}

#---------------------------------------
# Public Subnet C (AZ-c) - Web Tier
#---------------------------------------
resource "aws_subnet" "public_c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidrs["public_c"]
  availability_zone       = var.availability_zones[1]  # ap-northeast-2c
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-pub-c"
    Tier = "Public"
  }
}

#---------------------------------------
# Private Subnet A (AZ-a) - App Tier
#---------------------------------------
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_cidrs["private_a"]
  availability_zone = var.availability_zones[0]
  # map_public_ip_on_launch = false (기본값)

  tags = {
    Name = "${var.project_name}-priv-a"
    Tier = "Private"
  }
}

#---------------------------------------
# Private Subnet C (AZ-c) - App Tier
#---------------------------------------
resource "aws_subnet" "private_c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_cidrs["private_c"]
  availability_zone = var.availability_zones[1]

  tags = {
    Name = "${var.project_name}-priv-c"
    Tier = "Private"
  }
}

#===============================================================================
# NAT Gateway
#===============================================================================
# 용도: Private Subnet의 아웃바운드 인터넷 연결 (패키지 설치 등)
# 비용 절감: 단일 NAT GW 사용 (실무에서는 AZ별 NAT GW 권장)

#---------------------------------------
# Elastic IP for NAT Gateway
#---------------------------------------
resource "aws_eip" "nat" {
  domain = "vpc"  # VPC용 EIP

  tags = {
    Name = "${var.project_name}-nat-eip"
  }

  # IGW가 먼저 생성되어야 함
  depends_on = [aws_internet_gateway.main]
}

#---------------------------------------
# NAT Gateway
#---------------------------------------
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id  # Public Subnet에 위치

  tags = {
    Name = "${var.project_name}-nat-gw"
  }

  depends_on = [aws_internet_gateway.main]
}

#===============================================================================
# Route Tables
#===============================================================================

#---------------------------------------
# Public Route Table
#---------------------------------------
# 용도: Public Subnet → Internet Gateway로 라우팅
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  # 인터넷으로 나가는 트래픽은 IGW로
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-rt-public"
  }
}

#---------------------------------------
# Private Route Table
#---------------------------------------
# 용도: Private Subnet → NAT Gateway로 라우팅
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  # 인터넷으로 나가는 트래픽은 NAT GW로
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-rt-private"
  }
}

#===============================================================================
# Route Table Associations
#===============================================================================
# 서브넷과 라우트 테이블 연결

# Public Subnet A ↔ Public RT
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

# Public Subnet C ↔ Public RT
resource "aws_route_table_association" "public_c" {
  subnet_id      = aws_subnet.public_c.id
  route_table_id = aws_route_table.public.id
}

# Private Subnet A ↔ Private RT
resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

# Private Subnet C ↔ Private RT
resource "aws_route_table_association" "private_c" {
  subnet_id      = aws_subnet.private_c.id
  route_table_id = aws_route_table.private.id
}
