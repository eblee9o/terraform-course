locals {
  # EC2 컨테이너 인스턴스(Agent)에서 쓸 인스턴스 프로파일/롤 "이름"
  ec2_role_name             = var.ecs_ec2_role_name
  ec2_instance_profile_name = var.ecs_ec2_role_name

  # ECS 서비스 롤 / Consul 서버 롤 "이름"
  ecs_service_role_name        = var.ecs_service_role_name
  ecs_consul_server_role_name  = var.ecs_consul_server_role_name
}

########################################
# outputs: 다른 파일/워크플로에서 보기 쉽게 노출
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
