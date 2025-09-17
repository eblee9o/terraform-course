########################################
# ECS Service Role (create or reference)
# - 생성 여부: var.create_service_roles (vars.tf; 기본 false)
# - 역할 이름 : var.ecs_service_role_name (vars.tf; 기본 "ecs-service-role")
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

########################################
# ECS EC2 Instance Role & Instance Profile (create or reference)
# - 생성 여부: var.create_iam (vars.tf; 기본 true)
# - 역할/프로필 이름: var.ecs_ec2_role_name (vars.tf; 기본 "ecs-ec2-role")
#   * Instance Profile 이름은 Role 이름과 동일하게 사용
########################################

# 생성 모드
resource "aws_iam_role" "ecs_ec2_role" {
  count = var.create_iam ? 1 : 0

  name = var.ecs_ec2_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_instance_profile" "ecs_ec2_profile" {
  count = var.create_iam ? 1 : 0

  name = var.ecs_ec2_role_name
  role = aws_iam_role.ecs_ec2_role[0].name
}

resource "aws_iam_role_policy_attachment" "ecs_ec2_attach_core" {
  count      = var.create_iam ? 1 : 0
  role       = aws_iam_role.ecs_ec2_role[0].name
  # ECS 에이전트가 EC2에서 작동/등록하는 데 필요한 정책
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecs_ec2_attach_ssm" {
  count      = var.create_iam ? 1 : 0
  role       = aws_iam_role.ecs_ec2_role[0].name
  # SSM으로 접속/관리하고 싶을 때 편의상 추가(선택)
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# 참조 모드(이미 있는 역할/프로필 사용)
data "aws_iam_role" "ecs_ec2_role" {
  count = var.create_iam ? 0 : 1
  name  = var.ecs_ec2_role_name
}

data "aws_iam_instance_profile" "ecs_ec2_profile" {
  count = var.create_iam ? 0 : 1
  name  = var.ecs_ec2_role_name
}

########################################
# 공통 출력(둘 중 무엇을 쓰든 한 경로로 소비)
########################################

locals {
  ecs_service_role_name_effective = var.create_service_roles
    ? aws_iam_role.ecs_service_role[0].name
    : data.aws_iam_role.ecs_service_role[0].name

  ecs_service_role_arn_effective = var.create_service_roles
    ? aws_iam_role.ecs_service_role[0].arn
    : data.aws_iam_role.ecs_service_role[0].arn

  ecs_ec2_role_name_effective = var.create_iam
    ? aws_iam_role.ecs_ec2_role[0].name
    : data.aws_iam_role.ecs_ec2_role[0].name

  ecs_ec2_instance_profile_name_effective = var.create_iam
    ? aws_iam_instance_profile.ecs_ec2_profile[0].name
    : data.aws_iam_instance_profile.ecs_ec2_profile[0].name
}

output "ecs_service_role_name_effective" {
  value = local.ecs_service_role_name_effective
}

output "ecs_service_role_arn_effective" {
  value = local.ecs_service_role_arn_effective
}

output "ecs_ec2_role_name_effective" {
  value = local.ecs_ec2_role_name_effective
}

output "ecs_ec2_instance_profile_name_effective" {
  value = local.ecs_ec2_instance_profile_name_effective
}

