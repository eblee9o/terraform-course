data "cloudinit_config" "cloudinit-jenkins" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/x-shellscript"
    content = templatefile("scripts/jenkins-init.sh", {
      # DEVICE          = var.INSTANCE_DEVICE_NAME
      DEVICE          = ""
      JENKINS_VERSION = var.JENKINS_VERSION
      TF_VERSION      = var.TF_VERSION
    })
  }
}

# Jenkins 컨트롤러 전용 cloud-init
data "cloudinit_config" "jenkins_controller" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "jenkins-init.sh"
    content_type = "text/x-shellscript"
    # ⚠️ scripts/jenkins-init.sh.tftpl 파일은 $${...} 이스케이프된 template-safe 버전이어야 합니다
    content = templatefile("scripts/jenkins-init.sh", {
      DEVICE          = ""                  # 별도 데이터 디스크 없으면 빈 값
      JENKINS_VERSION = var.JENKINS_VERSION # 비워두면 최신 설치되게 스크립트 처리해도 OK
      TF_VERSION      = var.TF_VERSION      # 없으면 vars.tf에 default "1.9.5" 추가
    })
  }
}

data "cloudinit_config" "ecs" {
  gzip          = false
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
      #!/bin/bash
      echo "ECS_CLUSTER=example-cluster" > /etc/ecs/ecs.config
      systemctl enable --now ecs
    EOF
  }
}

