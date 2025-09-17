########################################
# ECS Service Role (create or reference)
# - 생성 여부: var.create_service_roles (vars.tf에 있음; 기본 false)
# - 역할 이름 : var.ecs_service_role_name (vars.tf에 있음; 기본 "ecs-service-role")
########################################

# 생성 모드
resource "aws_iam_role" "ecs_service_role" {
  count = var.create_service_roles ? 1 : 0

  name = var.ecs_service_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ecs.amazonaws.com" },
      Action   = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_service_role_attach" {
  count      = var.create_service_roles ? 1 : 0
  role       = aws_iam_role.ecs_service_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

# 참조 모드(이미 있는 역할만 사용)
data "aws_iam_role" "ecs_service_role" {
  count = var.create_service_roles ? 0 : 1
  name  = var.ecs_service_role_name
}

# 공통 출력(둘 중 무엇을 쓰든 한 경로로 소비)
locals {
  ecs_service_role_name_effective = var.create_service_roles ? aws_iam_role.ecs_service_role[0].name : data.aws_iam_role.ecs_service_role[0].name
  ecs_service_role_arn_effective  = var.create_service_roles ? aws_iam_role.ecs_service_role[0].arn  : data.aws_iam_role.ecs_service_role[0].arn
}

output "ecs_service_role_name_effective" {
  value = local.ecs_service_role_name_effective
}

output "ecs_service_role_arn_effective" {
  value = local.ecs_service_role_arn_effective
}

# EC2가 ECS에 붙을 권한
resource "aws_iam_role" "ecs_instance_role" {
  name = "ecsInstanceRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role_attach" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "ecsInstanceProfile"
  role = aws_iam_role.ecs_instance_role.name
}

