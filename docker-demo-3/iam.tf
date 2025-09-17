########################################
# Toggle: IAM 생성 여부 (권한 없으면 false)
########################################
variable "create_ecs_service_role" {
  type    = bool
  default = true
}

# locals.ecs_service_role_name 은 네 iam.tf에서 이미
#   ecs_service_role_name = var.ecs_service_role_name
# 으로 정의되어 있다고 했으므로 그대로 사용
# (예: var.ecs_service_role_name = "ecs-service-role")

########################################
# (A) 생성 모드
########################################
resource "aws_iam_role" "ecs_service_role" {
  count = var.create_ecs_service_role ? 1 : 0

  name = local.ecs_service_role_name
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
  name  = local.ecs_service_role_name
}

########################################
# 공통 출력용 값(생성/참조 어느 쪽이든 단일 경로)
########################################
locals {
  ecs_service_role_name_effective = var.create_ecs_service_role
    ? aws_iam_role.ecs_service_role[0].name
    : data.aws_iam_role.ecs_service_role[0].name

  ecs_service_role_arn_effective = var.create_ecs_service_role
    ? aws_iam_role.ecs_service_role[0].arn
    : data.aws_iam_role.ecs_service_role[0].arn
}

output "ecs_service_role_name_effective" {
  value = local.ecs_service_role_name_effective
}

output "ecs_service_role_arn_effective" {
  value = local.ecs_service_role_arn_effective
}

