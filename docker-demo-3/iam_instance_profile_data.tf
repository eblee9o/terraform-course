data "aws_iam_instance_profile" "jenkins_role" {
  name = var.instance_profile_name
}

