# EC2 인스턴스(컨테이너 인스턴스)용 Role
resource "aws_iam_role" "ecs_ec2" {
  count = var.create_iam ? 1 : 0
  name  = var.ecs_ec2_role_name
  path  = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid    = "",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = var.ecs_ec2_role_name
  }
}

# EC2 인스턴스 프로파일
resource "aws_iam_instance_profile" "ecs_ec2" {
  count = var.create_iam ? 1 : 0
  name  = var.ecs_ec2_role_name
  path  = "/"
  role  = aws_iam_role.ecs_ec2[0].name
}

# EC2 Role에 필요한 최소 권한(인라인) — ECS/ECR/CloudWatch Logs
# 운영에 맞춰 더 세분화할 수 있습니다.
resource "aws_iam_role_policy" "ecs_ec2_inline" {
  count = var.create_iam ? 1 : 0
  name  = "${var.ecs_ec2_role_name}-inline"
  role  = aws_iam_role.ecs_ec2[0].id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "ECSECRBasic"
        Effect   = "Allow"
        Action   = [
          "ecs:CreateCluster",
          "ecs:RegisterContainerInstance",
          "ecs:DeregisterContainerInstance",
          "ecs:DiscoverPollEndpoint",
          "ecs:Poll",
          "ecs:StartTelemetrySession",
          "ecs:Submit*",
          "ecs:StartTask",

          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      },
      {
        Sid      = "LogsAccess"
        Effect   = "Allow"
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# (선택) AWS 관리형 정책을 추가로 부여하고 싶다면(권장: 필요 시에만)
# resource "aws_iam_policy_attachment" "ecs_ec2_attach_ecr_ro" {
#   count      = var.create_iam ? 1 : 0
#   name       = "${var.ecs_ec2_role_name}-ecr-ro"
#   roles      = [aws_iam_role.ecs_ec2[0].name]
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
# }

# ECS 서비스용 Role (필요할 때만 생성)
resource "aws_iam_role" "ecs_service" {
  count = var.create_service_roles ? 1 : 0
  name  = var.ecs_service_role_name
  path  = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid    = "",
      Effect = "Allow",
      Principal = {
        Service = "ecs.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = var.ecs_service_role_name
  }
}

# ECS 서비스 Role에 권장되는 AWS 관리형 정책(서비스 역할용)
resource "aws_iam_policy_attachment" "ecs_service_attach" {
  count      = var.create_service_roles ? 1 : 0
  name       = "${var.ecs_service_role_name}-attach"
  roles      = [aws_iam_role.ecs_service[0].name]
  # 예: 기존 로그에서 보신 서비스 역할 정책
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

# Consul 서버용 Role (필요할 때만 생성)
resource "aws_iam_role" "ecs_consul_server" {
  count = var.create_service_roles ? 1 : 0
  name  = var.ecs_consul_server_role_name
  path  = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid    = "",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = var.ecs_consul_server_role_name
  }
}

########################################
# (B) 참조 경로 — 기본: 이미 존재하는 리소스만 조회
########################################

# EC2 Role/InstanceProfile (기존)
data "aws_iam_role" "ecs_ec2_existing" {
  count = var.create_iam ? 0 : 1
  name  = var.ecs_ec2_role_name
}

data "aws_iam_instance_profile" "ecs_ec2_existing" {
  count = var.create_iam ? 0 : 1
  name  = var.ecs_ec2_role_name
}

# ECS 서비스 Role (기존)
data "aws_iam_role" "ecs_service_existing" {
  count = var.create_service_roles ? 0 : 1
  name  = var.ecs_service_role_name
}

# Consul 서버 Role (기존)
data "aws_iam_role" "ecs_consul_server_existing" {
  count = var.create_service_roles ? 0 : 1
  name  = var.ecs_consul_server_role_name
}

########################################
# (C) 소비자가 사용할 단일 진실소스 (locals)
########################################
locals {
  # EC2 컨테이너 인스턴스용 Role/InstanceProfile 이름/ARN
  ec2_role_name             = var.create_iam ? aws_iam_role.ecs_ec2[0].name             : data.aws_iam_role.ecs_ec2_existing[0].name
  ec2_role_arn              = var.create_iam ? aws_iam_role.ecs_ec2[0].arn              : data.aws_iam_role.ecs_ec2_existing[0].arn
  ec2_instance_profile_name = var.create_iam ? aws_iam_instance_profile.ecs_ec2[0].name : data.aws_iam_instance_profile.ecs_ec2_existing[0].name
  ec2_instance_profile_arn  = var.create_iam ? aws_iam_instance_profile.ecs_ec2[0].arn  : data.aws_iam_instance_profile.ecs_ec2_existing[0].arn

  # ECS 서비스/Consul 역할
  ecs_service_role_name = var.create_service_roles ? aws_iam_role.ecs_service[0].name : data.aws_iam_role.ecs_service_existing[0].name
  ecs_service_role_arn  = var.create_service_roles ? aws_iam_role.ecs_service[0].arn  : data.aws_iam_role.ecs_service_existing[0].arn

  ecs_consul_server_role_name = var.create_service_roles ? aws_iam_role.ecs_consul_server[0].name : data.aws_iam_role.ecs_consul_server_existing[0].name
  ecs_consul_server_role_arn  = var.create_service_roles ? aws_iam_role.ecs_consul_server[0].arn  : data.aws_iam_role.ecs_consul_server_existing[0].arn
}

########################################
# (D) (선택) 다른 모듈/파일에서 쓰기 쉬우라고 output
########################################
output "ec2_role_name" {
  value = local.ec2_role_name
}
output "ec2_instance_profile_name" {
  value = local.ec2_instance_profile_name
}
output "ecs_service_role_name" {
  value = local.ecs_service_role_name
}
output "ecs_consul_server_role_name" {
  value = local.ecs_consul_server_role_name
}

