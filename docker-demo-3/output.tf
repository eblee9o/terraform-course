output "elb" {
  value = aws_elb.myapp-elb2.dns_name
}

output "jenkins" {
  value = aws_instance.jenkins-instance-2.public_ip
}

output "myapp-repository-URL" {
  value = aws_ecr_repository.myapp.repository_url
}

