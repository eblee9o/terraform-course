#ecr
variable "ecr_repo_name" {
  type    = string
  default = "myapp" # 필요하면 Jenkins에서 -var로 덮어쓰기
}

# 기존 레포지토리 조회(생성 안 함)
data "aws_ecr_repository" "myapp" {
  name = var.ecr_repo_name
}

# 공통 URL 로컬값
locals {
  myapp_repository_url = data.aws_ecr_repository.myapp.repository_url
}


# app

resource "aws_ecs_task_definition" "myapp-task-definition" {
  family = "myapp"
  container_definitions = templatefile("templates/app.json.tpl", {
    REPOSITORY_URL = replace(local.myapp_repository_url, "https://", "")
    APP_VERSION    = var.MYAPP_VERSION
  })
}

resource "aws_ecs_service" "myapp-service" {
  count           = var.MYAPP_SERVICE_ENABLE
  name            = "myapp"
  cluster         = aws_ecs_cluster.example-cluster.id
  task_definition = aws_ecs_task_definition.myapp-task-definition.arn
  desired_count   = 1
  iam_role        = local.ecs_service_role_name_effective

  load_balancer {
    elb_name       = aws_elb.myapp-elb2.name
    container_name = "myapp"
    container_port = 3000
  }
  lifecycle {
    ignore_changes = [task_definition]
  }
}

# load balancer
resource "aws_elb" "myapp-elb2" {
  name = "myapp-elb2"

  listener {
    instance_port     = 3000
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 30
    target              = "HTTP:3000/health"
    interval            = 60
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  subnets         = [aws_subnet.main-public-1.id, aws_subnet.main-public-2.id]
  security_groups = [aws_security_group.myapp-elb-securitygroup.id]

  tags = {
    Name = "myapp-elb2"
  }
}

