########################################
# iam.tf — 기존 리소스 “참조만” (생성/조회 안 함)
########################################

# (필수) 계정/파티션만 STS로 확인 — 이건 iam 권한 없이 됩니다.
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

# 이미 존재하는 역할/인스턴스 프로파일 “이름”을 변수로 받습니다.
variable "ecs_ec2_role_name" {
  type        = string
  default     = "ecs-ec2-role"
  description = "EC2 컨테이너 인스턴스가 사용할 기존 IAM Role/InstanceProfile 이름"
}
variable "ecs_service_role_name" {
  type        = string
  default     = "ecs-service-role"
}
variable "ecs_consul_server_role_name" {
  type        = string
  default     = "ecs-consul-server-role"
}

# (중요) 이 프로젝트에서 IAM을 생성하지 않음
variable "create_iam" {
  type        = bool
  default     = false
  description = "항상 false (권한 없음)."
}
variable "create_service_roles" {
  type        = bool
  default     = false
  description = "항상 false (권한 없음)."
}

# 여기서 “문자열로” ARN을 계산해서 다른 파일이 쓰도록 제공합니다.
locals {
  account_id  = data.aws_caller_identity.current.account_id
  partition   = data.aws_partition.current.partition

  ec2_role_name             = var.ecs_ec2_role_name
  ec2_instance_profile_name = var.ecs_ec2_role_name

  ec2_role_arn             = "arn:${local.partition}:iam::${local.account_id}:role/${var.ecs_ec2_role_name}"
  ec2_instance_profile_arn = "arn:${local.partition}:iam::${local.account_id}:instance-profile/${var.ecs_ec2_role_name}"

  ecs_service_role_name = var.ecs_service_role_name
  ecs_service_role_arn  = "arn:${local.partition}:iam::${local.account_id}:role/${var.ecs_service_role_name}"

  ecs_consul_server_role_name = var.ecs_consul_server_role_name
  ecs_consul_server_role_arn  = "arn:${local.partition}:iam::${local.account_id}:role/${var.ecs_consul_server_role_name}"
}

# (선택) 다른 파일에서 쓰기 쉬우라고 output
output "ec2_instance_profile_name" { value = local.ec2_instance_profile_name }
output "ecs_service_role_arn"      { value = local.ecs_service_role_arn }

