resource "aws_instance" "jenkins-instance-2" {
  # ami           = var.AMIS[var.AWS_REGION]
  ami            = data.aws_ami.ubuntu_2204.id
  instance_type = "t2.small"

  # the VPC subnet
  subnet_id = aws_subnet.main-public-1.id

  # the security group
  vpc_security_group_ids = [aws_security_group.jenkins-securitygroup.id]

  # the public SSH key
  key_name = key_name = var.key_name

  # user data
   user_data = data.cloudinit_config.cloudinit-jenkins.rendered

  # user_data 변경 시 인스턴스 자동 교체
  user_data_replace_on_change = true

  ebs_block_device {
    device_name           = "/dev/sdp"      # BDM에 없는 슬롯 하나 선택 (sdp 권장)
    volume_size           = 50
    volume_type           = "gp3"
    delete_on_termination = true            # 인스턴스 삭제 시 자동 정리
    encrypted             = true
  }

  tags = {
    Name = "jenkins-conn-instance"
    Role = "jenkins"
  }

}

resource "aws_ebs_volume" "jenkins-data" {
  availability_zone = "eu-west-1a"
  size              = 20
  type              = "gp2"
  tags = {
    Name = "jenkins-data"
  }
}

# resource "aws_volume_attachment" "jenkins-data-attachment" {
#   device_name = var.INSTANCE_DEVICE_NAME
#   volume_id   = aws_ebs_volume.jenkins-data.id
#   instance_id = aws_instance.jenkins-instance-2.id
#   stop_instance_before_detaching = true  # 분리 안전성 향상
# }

