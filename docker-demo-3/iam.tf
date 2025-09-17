########################################
# Toggle: IAM 생성 여부 (권한 없으면 false)
########################################
variable "create_ecs_service_role" {
  type    = bool
  default = true
}

# 이미 사용 중인 변수/locals와 호환
variable "ecs_service_role_name" {
  type    = string
  default = "ecs-service-role"
}

########################################
# (A) 생성 모드
########################################
resource "aws_iam_role" "ecs_service_role" {
  count = var.create_ecs_service_role ? 1 : 0

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
  count      = var.create_ecs_service_role ? 1 : 0
  role       = aws_iam_role.ecs_service_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

########################################
# (B) 참조 모드 (이미 있는 역할만 사용)
########################################
data "aws_iam_role" "ecs_service_role" {
  count = var.create_ecs_service_role ? 0 : 1
  name  = var.ecs_service_role_name
}

########################################
# 공통 값 (삼항은 한 줄로!)
########################################
locals {
  ecs_service_role_name_effective = var.create_ecs_service_role ? aws_iam_role.ecs_service_role[0].name : data.aws_iam_role.ecs_service_role[0].name
  ecs_service_role_arn_effective  = var.create_ecs_service_role ? aws_iam_role.ecs_service_role[0].arn  : data.aws_iam_role.ecs_service_role[0].arn

  # 기존 코드 호환: 너의 iam.tf에서 쓰던 local 이름으로도 노출
  ecs_service_role_name = local.ecs_service_role_name_effective
}

output "ecs_service_role_name_effective" {
  value = local.ecs_service_role_name_effective
}

output "ecs_service_role_arn_effective" {
  value = local.ecs_service_role_arn_effective
}

