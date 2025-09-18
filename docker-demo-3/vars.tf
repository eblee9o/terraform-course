variable "AWS_REGION" {
  default = "eu-west-1"
}

variable "PATH_TO_PRIVATE_KEY" {
  default = "mykey"
}

variable "PATH_TO_PUBLIC_KEY" {
  default = "mykey.pub"
}

variable "ECS_INSTANCE_TYPE" {
  default = "t2.micro"
}

variable "ECS_AMIS" {
  type = map(string)
  default = {
    us-east-1 = "ami-1924770e"
    us-west-2 = "ami-56ed4936"
    eu-west-1 = "ami-c8337dbb"
  }
}

# Full List: http://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-optimized_AMI.html

variable "AMIS" {
  type = map(string)
  default = {
    us-east-1 = "ami-01b996646377b6619"
    us-west-2 = "ami-0637e7dc7fcc9a2d9"
    eu-west-1 = "ami-081ff4b9aa4e81a08"
  }
}

variable "INSTANCE_DEVICE_NAME" {
  default = "/dev/sdg"
}

variable "JENKINS_VERSION" {
  default = "2.319.2"
}

variable "create_iam" {
  type    = bool
  default = true
}

variable "create_service_roles" {
  type    = bool
  default = false
}


variable "create_backend_bucket" {
  type    = bool
  default = false
}

variable "backend_bucket_name" {
  default = "terraform-state-8lmwdo9p"
}

variable "ecs_ec2_role_name" {
  type    = string
  default = "ecs-ec2-role"
}

variable "ecs_service_role_name" {
  type    = string
  # default = "ecs-service-role"
  default  = "ecsInstanceRole"
}

variable "ecs_consul_server_role_name" {
  type    = string
  default = "ecs-consul-server-role"
}


variable "TF_VERSION" {
  description = "Terraform version to install on Jenkins node"
  type        = string
  default     = "1.9.5"
}

variable "key_name" {
  type    = string
  default = "mykeypair" # 실제 키페어 이름
}

variable "instance_profile_name" {
  type    = string
  default = "jenkins-role" # 실제 인스턴스 프로파일 이름
}

