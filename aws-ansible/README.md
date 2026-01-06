# AWS 3-Tier HA Architecture - IaC

## 프로젝트 개요

KVM 기반 3-Tier 웹 애플리케이션을 AWS로 마이그레이션하고, Terraform + Ansible을 사용하여 Infrastructure as Code로 자동화한 프로젝트입니다.

## 아키텍처

```
                              [Internet]
                                   │ :80
                                   ▼
┌──────────────────────────────────────────────────────────────────┐
│                    External ALB (portfolio-alb)                  │
│                          Multi-AZ (Public)                       │
└─────────────────────────────┬────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
┌─────────────────────────┐     ┌─────────────────────────┐
│  Public Subnet A        │     │  Public Subnet C        │
│  (10.0.1.0/24)          │     │  (10.0.3.0/24)          │
│  EC2: Web-A (Nginx)     │     │  EC2: Web-C (Nginx)     │
└───────────┬─────────────┘     └───────────┬─────────────┘
            └───────────┬───────────────────┘
                        ▼ :8080
┌──────────────────────────────────────────────────────────────────┐
│                Internal ALB (portfolio-internal-alb)             │
│                          Multi-AZ (Private)                      │
└─────────────────────────────┬────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
┌─────────────────────────┐     ┌─────────────────────────┐
│  Private Subnet A       │     │  Private Subnet C       │
│  (10.0.2.0/24)          │     │  (10.0.4.0/24)          │
│  EC2: App-A (WildFly)   │     │  EC2: App-C (WildFly)   │
└───────────┬─────────────┘     └───────────┬─────────────┘
            └───────────┬───────────────────┘
                        ▼ :5432
┌──────────────────────────────────────────────────────────────────┐
│                    RDS (portfolio-db)                            │
│               PostgreSQL 16 (Private Subnet)                     │
└──────────────────────────────────────────────────────────────────┘
```

## 디렉토리 구조

```
aws-3tier-iac/
├── terraform/
│   ├── main.tf              # Provider, Backend 설정
│   ├── variables.tf         # 입력 변수 정의
│   ├── outputs.tf           # 출력 값 정의
│   ├── terraform.tfvars     # 변수 값 (Git 제외)
│   ├── vpc.tf               # VPC, Subnet, IGW, NAT, Route Table
│   ├── security-groups.tf   # Security Groups
│   ├── ec2.tf               # EC2 Instances
│   ├── alb.tf               # Application Load Balancers
│   └── rds.tf               # RDS PostgreSQL
├── ansible/
│   ├── ansible.cfg          # Ansible 설정
│   ├── inventory/
│   │   └── aws_hosts.ini    # 호스트 인벤토리
│   ├── group_vars/
│   │   ├── all.yml          # 전체 공통 변수
│   │   ├── web.yml          # Web 그룹 변수
│   │   └── app.yml          # App 그룹 변수
│   ├── roles/
│   │   ├── common/          # 공통 설정
│   │   ├── nginx/           # Nginx 설치/설정
│   │   └── wildfly/         # WildFly 설치/설정
│   └── playbooks/
│       ├── site.yml         # 전체 실행
│       ├── web.yml          # Web만 실행
│       └── app.yml          # App만 실행
├── .gitignore
└── README.md
```

## 사전 요구사항

1. **AWS CLI** 설치 및 프로파일 구성
2. **Terraform** >= 1.0.0
3. **AWS 키페어** 생성 완료

## 사용 방법

### 1. 변수 파일 설정

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

`terraform.tfvars` 파일을 편집하여 실제 값 입력:
- `ec2_key_name`: AWS에 등록된 키페어 이름
- `my_ip`: SSH 접속 허용 IP (예: "203.0.113.50/32")
- `db_password`: RDS 비밀번호

### 2. Terraform 초기화 및 적용

```bash
# 초기화
terraform init

# 실행 계획 확인
terraform plan

# 인프라 생성
terraform apply
```

### 3. 출력 값 확인

```bash
terraform output

# 특정 출력만 확인
terraform output external_alb_dns
terraform output web_public_ips
```

---

## Ansible 사용 방법

### 1. 인벤토리 설정

Terraform output을 기반으로 `ansible/inventory/aws_hosts.ini` 수정:

`WEB_A_PUBLIC_IP`,
`WEB_C_PUBLIC_IP`,
`APP_A_PRIVATE_IP`,
`APP_C_PRIVATE_IP`,
`INTERNAL_ALB_DNS`,
`RDS_ENDPOINT`

```bash
# Terraform 출력 확인
cd terraform
terraform output web_public_ips
terraform output app_private_ips
terraform output internal_alb_dns
terraform output rds_endpoint
```

### 2. SSH 키 경로 설정

`ansible/ansible.cfg`에서 SSH 키 경로 수정:

```ini
private_key_file = ~/.ssh/your-key.pem
```

### 3. 연결 테스트

```bash
cd ansible
ansible web -m ping
ansible app -m ping
```

### 4. Playbook 실행

```bash
# 전체 실행 (Web + App)
ansible-playbook playbooks/site.yml -e "db_password=YourDBPassword"

# Web만 실행
ansible-playbook playbooks/web.yml

# App만 실행
ansible-playbook playbooks/app.yml -e "db_password=YourDBPassword"
```

## 리소스 정리

```bash
terraform destroy
```

## 참고사항

- Rocky Linux 9 SSH 사용자: `rocky`
- WildFly 경로: `/opt/wildfly`
- Nginx 설정: `/etc/nginx/conf.d/`
- SELinux 설정 필요: `setsebool -P httpd_can_network_connect 1`

## 라이선스

MIT License
