resource "aws_ecs_cluster" "example-cluster" {
  name = "example-cluster"
}

# Ubuntu 22.04 (예시: Canonical 공식 AMI) — 필요 시 필터 조정
data "aws_ami" "ubuntu_2204" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}


resource "aws_launch_template" "ecs_lt" {
  name_prefix = "ecs-lt-"

  # 기존 AMI 맵을 그대로 활용 (원래 쓰던 값 유지)
  image_id      = data.aws_ami.ubuntu_2204.id
  instance_type = var.ECS_INSTANCE_TYPE
  key_name      = aws_key_pair.mykeypair.key_name

  # Launch Template에서는 block으로 지정
  iam_instance_profile {
    # name = local.ec2_instance_profile_name
    name = data.aws_iam_instance_profile.jenkins-role.name
  }

  # SG는 vpc_security_group_ids로 설정
  vpc_security_group_ids = [aws_security_group.ecs-securitygroup.id]

  # LT의 user_data는 base64 인코딩 필요
  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo 'ECS_CLUSTER=example-cluster' > /etc/ecs/ecs.config
    systemctl enable --now ecs
  EOF
  )

  lifecycle {
    create_before_destroy = true
  }
}

# ✅ ASG에서 Launch Configuration → Launch Template로 변경
resource "aws_autoscaling_group" "ecs-jenkins-autoscaling" {
  name               = "ecs-jenkins-autoscaling"
  vpc_zone_identifier = [
    aws_subnet.main-public-1.id,
    aws_subnet.main-public-2.id
  ]

  min_size        = 1
  max_size        = 1
  desired_capacity = 1

  # 이 블록으로 대체
  launch_template {
    id      = aws_launch_template.ecs_lt.id
    version = "$Latest"  # 또는 "$Default"
  }

  tag {
    key                 = "Name"
    value               = "ecs-ec2-container"
    propagate_at_launch = true
  }

}

