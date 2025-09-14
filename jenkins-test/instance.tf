# Ubuntu 22.04 (Jammy) 최신 AMI 자동 선택
data "aws_ami" "ubuntu_2204" {
  owners      = ["099720109477"] # Canonical
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu-pro-server/images/hvm-ssd/ubuntu-bionic-18.04-amd64-pro-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "jenkins_test" {
  ami                    = data.aws_ami.ubuntu_2204.id
  instance_type          = "t2.small"
  subnet_id              = aws_subnet.main-public-1.id
  vpc_security_group_ids = [aws_security_group.jenkins-securitygroup.id]
  key_name               = aws_key_pair.mykeypair.key_name

  # cloud-init (아래 3)의 data.cloudinit_config.jenkins.rendered 사용)
  user_data                   = data.cloudinit_config.cloudinit-jenkins.rendered
  user_data_replace_on_change = true
  # iam instance profile
  iam_instance_profile = aws_iam_instance_profile.jenkins-role.name

  tags = {
    Name = "jenkins-22-04"
  }
}



# data "aws_ami" "ubuntu" {
#   most_recent = true
# 
#   filter {
#     name   = "name"
#     values = ["ubuntu-pro-server/images/hvm-ssd/ubuntu-bionic-18.04-amd64-pro-*"]
#   }
# 
#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }
# 
#   owners = ["099720109477"] # Canonical
# }


######## 원래 주석 ####
# data "aws_ami" "ubuntu" {
#   most_recent = true
# 
#   filter {
#     name   = "name"
#     values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
#   }
# 
#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }
# 
#   owners = ["099720109477"] # Canonical
# }

# resource "aws_instance" "jenkins-instance" {
#   ami           = data.aws_ami.ubuntu.id
#   instance_type = "t2.small"
# 
#   # the VPC subnet
#   subnet_id = aws_subnet.main-public-1.id
# 
#   # the security group
#   vpc_security_group_ids = [aws_security_group.jenkins-securitygroup.id]
# 
#   # the public SSH key
#   key_name = aws_key_pair.mykeypair.key_name
# 
#   # user data
#   user_data = data.cloudinit_config.cloudinit-jenkins.rendered
# 
#   # iam instance profile
#   iam_instance_profile = aws_iam_instance_profile.jenkins-role.name
# }

# resource "aws_ebs_volume" "jenkins-data" {
#   availability_zone = "eu-west-1a"
#   size              = 20
#   type              = "gp2"
#   tags = {
#     Name = "jenkins-data"
#   }
# }

# 새 데이터 볼륨 (AZ는 반드시 인스턴스와 같아야 함)
resource "aws_ebs_volume" "jenkins_data_new" {
  availability_zone = "eu-west-1a"
  size              = 20
  type              = "gp2"
  tags              = { Name = "jenkins-data-new" }
}

# resource "aws_volume_attachment" "jenkins-data-attachment" {
#   device_name = var.INSTANCE_DEVICE_NAME
#   volume_id   = aws_ebs_volume.jenkins-data.id
#   # instance_id  = aws_instance.jenkins-instance.id
#   instance_id  = aws_instance.jenkins_test.id
#   skip_destroy = true
# }

# 새 인스턴스에 부착
resource "aws_volume_attachment" "jenkins_data_new_attachment" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.jenkins_data_new.id
  instance_id = aws_instance.jenkins_test.id
}

resource "aws_instance" "app-instance" {
  count         = var.APP_INSTANCE_COUNT
  ami           = var.APP_INSTANCE_AMI
  instance_type = "t2.micro"

  # the VPC subnet
  subnet_id = aws_subnet.main-public-1.id

  # the security group
  vpc_security_group_ids = [aws_security_group.app-securitygroup.id]

  # the public SSH key
  key_name = aws_key_pair.mykeypair.key_name
}

