resource "aws_ecs_cluster" "example-cluster" {
  name = "example-cluster"
}

data "aws_ssm_parameter" "ecs_al2_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}


resource "aws_launch_template" "ecs_lt" {
  name_prefix = "ecs-lt-"

  # 기존 AMI 맵을 그대로 활용 (원래 쓰던 값 유지)
  image_id      = data.aws_ssm_parameter.ecs_al2_ami.value
  instance_type = var.ECS_INSTANCE_TYPE
  key_name      = var.key_name

  # Launch Template에서는 block으로 지정
  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }

  # SG는 vpc_security_group_ids로 설정
  vpc_security_group_ids = [aws_security_group.ecs-securitygroup.id]

  # user_data
  user_data = data.cloudinit_config.ecs.rendered

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [user_data]
  }

}

resource "aws_autoscaling_group" "ecs-jenkins-autoscaling" {
  name = "ecs-jenkins-autoscaling"
  vpc_zone_identifier = [aws_subnet.main-public-1.id, aws_subnet.main-public-2.id]

  min_size         = 1
  max_size         = 1
  desired_capacity = 1

  launch_template {
    id      = aws_launch_template.ecs_lt.id
    version = "$Latest" 
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 100
      instance_warmup        = 60
    }
    triggers = ["launch_template"]
  }


  tag {
    key                 = "Name"
    value               = "ecs-ec2-container"
    propagate_at_launch = true
  }

}



