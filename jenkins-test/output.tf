output "jenkins-ip" {
  # value = [aws_instance.jenkins-instance.*.public_ip]
  value = [aws_instance.jenkins_test.*.public_ip]
}

output "app-ip" {
  value = [aws_instance.app-instance.*.public_ip]
}

output "s3-bucket" {
  value = aws_s3_bucket.terraform-state.bucket
}

output "jenkins_url" {
  value = "http://${aws_instance.jenkins_test.public_ip}:8080"
}

output "jenkins_initial_password" {
  value       = "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
  description = "SSH 접속 후 위 명령으로 초기 비번 확인"
}

