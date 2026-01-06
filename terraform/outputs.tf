#===============================================================================
# outputs.tf - 출력 값 정의
#===============================================================================
# 역할: Terraform 적용 후 확인이 필요한 값들 출력
# 용도:
#   - Ansible 인벤토리 생성에 활용
#   - 접속 테스트 시 참조
#   - Phase 1 환경변수 파일 대체
#===============================================================================

#===============================================================================
# VPC Outputs
#===============================================================================
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR Block"
  value       = aws_vpc.main.cidr_block
}

#===============================================================================
# Subnet Outputs
#===============================================================================
output "public_subnet_ids" {
  description = "Public Subnet IDs (for reference)"
  value = {
    public_a = aws_subnet.public_a.id
    public_c = aws_subnet.public_c.id
  }
}

output "private_subnet_ids" {
  description = "Private Subnet IDs (for reference)"
  value = {
    private_a = aws_subnet.private_a.id
    private_c = aws_subnet.private_c.id
  }
}

#===============================================================================
# EC2 Outputs
#===============================================================================
# Web Tier
output "web_instance_ids" {
  description = "Web Tier EC2 Instance IDs"
  value = {
    web_a = aws_instance.web_a.id
    web_c = aws_instance.web_c.id
  }
}

output "web_public_ips" {
  description = "Web Tier Public IPs (SSH 접속용)"
  value = {
    web_a = aws_instance.web_a.public_ip
    web_c = aws_instance.web_c.public_ip
  }
}

output "web_private_ips" {
  description = "Web Tier Private IPs"
  value = {
    web_a = aws_instance.web_a.private_ip
    web_c = aws_instance.web_c.private_ip
  }
}

# App Tier
output "app_instance_ids" {
  description = "App Tier EC2 Instance IDs"
  value = {
    app_a = aws_instance.app_a.id
    app_c = aws_instance.app_c.id
  }
}

output "app_private_ips" {
  description = "App Tier Private IPs (Bastion 경유 접속용)"
  value = {
    app_a = aws_instance.app_a.private_ip
    app_c = aws_instance.app_c.private_ip
  }
}

#===============================================================================
# ALB Outputs
#===============================================================================
output "external_alb_dns" {
  description = "External ALB DNS Name (웹 접속 주소)"
  value       = aws_lb.external.dns_name
}

output "external_alb_arn" {
  description = "External ALB ARN"
  value       = aws_lb.external.arn
}

output "internal_alb_dns" {
  description = "Internal ALB DNS Name (Nginx upstream 설정용)"
  value       = aws_lb.internal.dns_name
}

output "internal_alb_arn" {
  description = "Internal ALB ARN"
  value       = aws_lb.internal.arn
}

#===============================================================================
# RDS Outputs
#===============================================================================
output "rds_endpoint" {
  description = "RDS Endpoint (WildFly 데이터소스 설정용)"
  value       = aws_db_instance.main.endpoint
}

output "rds_address" {
  description = "RDS Address (호스트명만)"
  value       = aws_db_instance.main.address
}

output "rds_port" {
  description = "RDS Port"
  value       = aws_db_instance.main.port
}

output "rds_database_name" {
  description = "RDS Database Name"
  value       = aws_db_instance.main.db_name
}

#===============================================================================
# Security Group Outputs
#===============================================================================
output "security_group_ids" {
  description = "Security Group IDs"
  value = {
    alb          = aws_security_group.alb.id
    web          = aws_security_group.web.id
    internal_alb = aws_security_group.internal_alb.id
    app          = aws_security_group.app.id
    db           = aws_security_group.db.id
  }
}

#===============================================================================
# AMI Information Commented Out (Hardcoded in ec2.tf)
#===============================================================================
#output "rocky9_ami_id" {
#  description = "Rocky Linux 9 AMI ID used"
#  value       = data.aws_ami.rocky9.id
#}
#
#output "rocky9_ami_name" {
#  description = "Rocky Linux 9 AMI Name"
#  value       = data.aws_ami.rocky9.name
#}

#===============================================================================
# 접속 정보 요약
#===============================================================================
output "connection_info" {
  description = "접속 정보 요약"
  value = <<-EOT
    
    ============================================
    AWS 3-Tier Architecture - Connection Info
    ============================================
    
    [Web Access]
    URL: http://${aws_lb.external.dns_name}
    
    [SSH Access - Web Servers]
    Web-A: ssh -i <key.pem> rocky@${aws_instance.web_a.public_ip}
    Web-C: ssh -i <key.pem> rocky@${aws_instance.web_c.public_ip}
    
    [SSH Access - App Servers (via Web as Bastion)]
    From Web-A: ssh rocky@${aws_instance.app_a.private_ip}
    From Web-C: ssh rocky@${aws_instance.app_c.private_ip}
    
    [Internal ALB DNS (for Nginx upstream)]
    ${aws_lb.internal.dns_name}
    
    [RDS Connection]
    Host: ${aws_db_instance.main.address}
    Port: ${aws_db_instance.main.port}
    Database: ${aws_db_instance.main.db_name}
    
    ============================================
  EOT
}

#===============================================================================
# Ansible Inventory Helper
#===============================================================================
output "ansible_inventory" {
  description = "Ansible 인벤토리용 호스트 정보"
  value = {
    web_servers = {
      web_a = {
        ansible_host = aws_instance.web_a.public_ip
        private_ip   = aws_instance.web_a.private_ip
      }
      web_c = {
        ansible_host = aws_instance.web_c.public_ip
        private_ip   = aws_instance.web_c.private_ip
      }
    }
    app_servers = {
      app_a = {
        ansible_host = aws_instance.app_a.private_ip
      }
      app_c = {
        ansible_host = aws_instance.app_c.private_ip
      }
    }
    vars = {
      internal_alb_dns = aws_lb.internal.dns_name
      rds_endpoint     = aws_db_instance.main.address
      rds_port         = aws_db_instance.main.port
      rds_database     = aws_db_instance.main.db_name
    }
  }
}

#===============================================================================
# Monitoring Outputs
#===============================================================================
output "sns_topic_arn" {
  description = "SNS Topic ARN for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "cloudwatch_alarms" {
  description = "CloudWatch Alarm names"
  value = {
    ec2_cpu = {
      web_a = aws_cloudwatch_metric_alarm.web_a_cpu.alarm_name
      web_c = aws_cloudwatch_metric_alarm.web_c_cpu.alarm_name
      app_a = aws_cloudwatch_metric_alarm.app_a_cpu.alarm_name
      app_c = aws_cloudwatch_metric_alarm.app_c_cpu.alarm_name
    }
    rds = {
      cpu         = aws_cloudwatch_metric_alarm.rds_cpu.alarm_name
      storage     = aws_cloudwatch_metric_alarm.rds_storage.alarm_name
      connections = aws_cloudwatch_metric_alarm.rds_connections.alarm_name
    }
    alb = {
      elb_5xx        = aws_cloudwatch_metric_alarm.alb_5xx.alarm_name
      target_5xx     = aws_cloudwatch_metric_alarm.alb_target_5xx.alarm_name
      unhealthy_hosts = aws_cloudwatch_metric_alarm.alb_unhealthy_hosts.alarm_name
    }
  }
}
