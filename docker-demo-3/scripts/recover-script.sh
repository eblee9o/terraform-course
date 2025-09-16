#!/bin/sh
set -eu
export DEBIAN_FRONTEND=noninteractive

# 0) 기본 도구
sudo apt-get update
sudo apt-get install -y curl gnupg ca-certificates apt-transport-https

# 1) Jenkins APT 키/리포 (2023 키, dearmor 방식)
sudo rm -f /etc/apt/sources.list.d/jenkins.list /etc/apt/keyrings/jenkins.gpg /usr/share/keyrings/jenkins-keyring.asc || true
sudo mkdir -p /etc/apt/keyrings
TMPKEY="$(mktemp)"
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key -o "$TMPKEY"
sudo gpg --dearmor -o /etc/apt/keyrings/jenkins.gpg "$TMPKEY"
rm -f "$TMPKEY"
echo 'deb [signed-by=/etc/apt/keyrings/jenkins.gpg] https://pkg.jenkins.io/debian-stable binary/' \
  | sudo tee /etc/apt/sources.list.d/jenkins.list >/dev/null
sudo apt-get update

# 2) Jenkins 설치 (유저/서비스 자동 생성)
if ! dpkg -s jenkins >/dev/null 2>&1; then
  sudo apt-get install -y jenkins
fi

# 3) Docker 충돌 정리 → Ubuntu docker.io로 통일
sudo apt-mark unhold docker.io docker-ce docker-ce-cli containerd containerd.io >/dev/null 2>&1 || true
sudo apt-get remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin >/dev/null 2>&1 || true
sudo apt-get -y -f install
sudo apt-get update
sudo apt-get install -y docker.io

# 4) 데몬/권한/서비스
sudo systemctl enable --now docker
if ! id jenkins >/dev/null 2>&1; then
  sudo useradd -r -m -s /bin/false jenkins
fi
sudo usermod -aG docker jenkins || true
sudo systemctl enable --now jenkins || true
sudo systemctl restart jenkins || true

# 5) 확인
echo "=== Jenkins/Docker 확인 ==="
sudo -u jenkins -H sh -c 'id; which docker || true; docker --version || true'
sudo ss -lntp | grep :8080 || echo "8080 not listening yet (잠시 후 재확인)"
if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
  sudo cat /var/lib/jenkins/secrets/initialAdminPassword
else
  echo "init password not ready yet"
fi

