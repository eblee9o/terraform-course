########################################
# ECS Service Role (create or reference)
# - var.create_service_roles = true 면 생성, false 면 기존 역할을 조회
# - var.ecs_service_role_name 은 역할 이름(기본: "ecs-service-role")
########################################

# 생성 모드
resource "aws_iam_role" "ecs_service_role" {
  name = "ecsServiceRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ecs.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_service_role_attach" {
  count      = var.create_service_roles ? 1 : 0
  role       = aws_iam_role.ecs_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

# 참조 모드(이미 있는 역할 사용)
data "aws_iam_role" "ecs_service_role" {
  count = var.create_service_roles ? 0 : 1
  name  = var.ecs_service_role_name
}

# ecs 서비스가 ELB에 접근할 수 있도록 trust policy
data "aws_iam_policy_document" "ecs_service_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}


########################################
# EC2(컨테이너 인스턴스)용 IAM Role / Instance Profile
########################################
resource "aws_iam_role" "ecs_instance_role" {
  name = "ecsInstanceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
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


