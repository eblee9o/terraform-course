# data "cloudinit_config" "cloudinit-jenkins" {
#   gzip          = false
#   base64_encode = false
# 
#   part {
#     content_type = "text/x-shellscript"
#     content      = templatefile("scripts/jenkins-init.sh", {
#       DEVICE            = var.INSTANCE_DEVICE_NAME
#       JENKINS_VERSION   = var.JENKINS_VERSION
#       TERRAFORM_VERSION = var.TERRAFORM_VERSION
#     })
#   }
# }


data "cloudinit_config" "cloudinit-jenkins" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content      = <<-CLOUDCFG
#cloud-config
package_update: true
package_upgrade: true
packages:
  - ca-certificates
  - curl
  - gnupg
  - unzip
  - openjdk-17-jre

runcmd:
  - [ bash, -lc, "set -euxo pipefail; export DEBIAN_FRONTEND=noninteractive" ]

  # Jenkins repo (2023 키) 등록
  - [ bash, -lc, "install -m 0755 -d /etc/apt/keyrings" ]
  - [ bash, -lc, "curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key -o /etc/apt/keyrings/jenkins-keyring.asc" ]
  - [ bash, -lc, "echo 'deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/' | tee /etc/apt/sources.list.d/jenkins.list > /dev/null" ]

  # (선택) HashiCorp 리포 – Jenkins 빌드에 terraform/packer 쓰면 함께 설치
  - [ bash, -lc, "curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg >/dev/null" ]
  - [ bash, -lc, "echo 'deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(. /etc/os-release && echo $VERSION_CODENAME) main' | tee /etc/apt/sources.list.d/hashicorp.list > /dev/null" ]

  - [ bash, -lc, "apt-get update" ]
  - [ bash, -lc, "apt-get install -y jenkins terraform packer || apt-get install -y jenkins" ]  # hashicorp 리포가 실패하면 jenkins만이라도

  - [ bash, -lc, "systemctl enable --now jenkins" ]
  - [ bash, -lc, "ss -ltnp | grep :8080 || journalctl -u jenkins -n 200 --no-pager || true" ]

final_message: "Jenkins is installed. Initial password in /var/lib/jenkins/secrets/initialAdminPassword"
CLOUDCFG
  }
}

