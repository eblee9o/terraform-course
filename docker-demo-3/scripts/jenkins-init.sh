#!/bin/bash
# ------------------------------------------------------------------------------
# Jenkins EC2 Init - Ubuntu
# - Java 17, Jenkins LTS, Docker, (옵션) Terraform/AWS CLI
# - /var/lib/jenkins : 추가 디스크 있으면 자동 포맷/마운트, 없으면 루트 사용
# ------------------------------------------------------------------------------
set -euo pipefail
DEBIAN_FRONTEND=noninteractive

# ⚠️ 이 3줄은 Terraform이 templatefile()로 치환합니다(기본값 문법 금지).
DEVICE="${DEVICE}"                # 예: "/dev/sdp" 또는 빈 문자열 ""
JENKINS_VERSION="${JENKINS_VERSION}"
TF_VERSION="${TF_VERSION}"

# 빈 값일 때 기본값 적용
if [[ -z "$${TF_VERSION}" ]]; then TF_VERSION="1.9.5"; fi

log() { echo "[jenkins-init] $*"; }

prepare_mount() {
  local MNT="/var/lib/jenkins"
  mkdir -p "$MNT"

  # 1) 지정된 DEVICE가 블록디바이스면 우선 사용
  local TARGET_DEV=""
  if [[ -n "$${DEVICE}" && -b "$${DEVICE}" ]]; then
    TARGET_DEV="$${DEVICE}"
  fi

  # 2) 못 찾았으면 '미마운트 디스크' 자동 탐지 (Nitro/Xen 모두 대응)
  if [[ -z "$TARGET_DEV" ]]; then
    for d in /dev/disk/by-id/nvme-Amazon_Elastic_Block_Store* /dev/nvme?n1 /dev/xvd? /dev/sd?; do
      [[ -e "$d" || -b "$d" ]] || continue
      local real; real="$(readlink -f "$d" 2>/dev/null || echo "$d")"
      local mp; mp="$(lsblk -no MOUNTPOINT "$real" 2>/dev/null | head -n1)"
      [[ -z "$mp" ]] || continue
      TARGET_DEV="$real"
      break
    done
  fi

  if [[ -z "$TARGET_DEV" ]]; then
    log "추가 디스크 없음 → $MNT 를 루트 디스크에 사용(마운트 스킵)"
    chown -R jenkins:jenkins "$MNT" 2>/dev/null || true
    chmod 750 "$MNT" || true
    return
  fi

  log "선택된 디바이스: $TARGET_DEV"

  # 파일시스템 유무 확인
  local DEV_FS
  DEV_FS="$(blkid -o value -s TYPE "$TARGET_DEV" || true)"

  if [[ -z "$DEV_FS" ]]; then
    log "파일시스템 없음 → ext4로 포맷"
    mkfs.ext4 -F "$TARGET_DEV"
    DEV_FS="ext4"
  else
    log "기존 파일시스템 감지: $DEV_FS"
  fi

  # fstab에는 UUID로 등록
  local UUID
  UUID="$(blkid -o value -s UUID "$TARGET_DEV" || true)"
  if ! grep -qE " $MNT " /etc/fstab 2>/dev/null; then
    if [[ -n "$UUID" ]]; then
      echo "UUID=$UUID $MNT $DEV_FS defaults,nofail 0 2" >> /etc/fstab
    else
      echo "$TARGET_DEV $MNT $DEV_FS defaults,nofail 0 2" >> /etc/fstab
    fi
  fi

  if mount "$MNT"; then
    log "$MNT 마운트 완료"
  else
    log "경고: $MNT 마운트 실패(루트 디스크 사용으로 계속 진행)"
  fi

  chown -R jenkins:jenkins "$MNT" 2>/dev/null || true
  chmod 750 "$MNT" || true
}

install_java17_and_utils() {
  log "필수 패키지 설치"
  apt-get update
  apt-get install -y curl gnupg unzip ca-certificates apt-transport-https
  log "Java 17 설치"
  apt-get install -y openjdk-17-jre-headless
  log "Java 버전: $(java -version 2>&1 | head -n1)"
}

install_jenkins() {
  log "Jenkins 저장소 키/리스트 갱신(2023 키, dearmor)"
  mkdir -p /etc/apt/keyrings

  # 새 키로 교체
  curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key \
    | gpg --dearmor | tee /etc/apt/keyrings/jenkins.gpg >/dev/null
  chmod 644 /etc/apt/keyrings/jenkins.gpg

  # repo 파일도 새 signed-by로 작성
  echo "deb [signed-by=/etc/apt/keyrings/jenkins.gpg] https://pkg.jenkins.io/debian-stable binary/" \
    | tee /etc/apt/sources.list.d/jenkins.list >/dev/null

  apt-get update

  if dpkg -l | grep -q '^ii\s\+jenkins\s'; then
    log "Jenkins 이미 설치됨"
  else
    if [[ -n "$${JENKINS_VERSION}" ]]; then
      log "Jenkins 고정 버전 설치: $${JENKINS_VERSION}"
      apt-get install -y "jenkins=$${JENKINS_VERSION}" || apt-get install -y jenkins
    else
      log "Jenkins 최신 설치"
      apt-get install -y jenkins
    fi
  fi

  mkdir -p /var/lib/jenkins
  chown -R jenkins:jenkins /var/lib/jenkins
  chmod 750 /var/lib/jenkins
}

install_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    log "Docker 설치"
    apt-get install -y docker.io
    systemctl enable --now docker
  else
    log "Docker 이미 설치됨"
    systemctl enable --now docker || true
  fi
  usermod -aG docker jenkins || true
}

start_jenkins_and_wait_password() {
  log "Jenkins 서비스 시작"
  systemctl daemon-reload || true
  systemctl enable jenkins
  systemctl restart jenkins

  for i in {1..40}; do
    if [[ -f /var/lib/jenkins/secrets/initialAdminPassword ]]; then
      break
    fi
    sleep 2
  done

  if [[ -f /var/lib/jenkins/secrets/initialAdminPassword ]]; then
    local PASS; PASS="$(cat /var/lib/jenkins/secrets/initialAdminPassword)"
    log "초기 비밀번호 준비됨 → /root/jenkins-initial-admin-password 저장"
    echo "$${PASS}" > /root/jenkins-initial-admin-password
    chmod 600 /root/jenkins-initial-admin-password
  else
    log "경고: 초기 비밀번호 파일이 생성되지 않음. 로그 확인 필요."
    journalctl -u jenkins -n 200 --no-pager || true
  fi
}

install_optional_tools() {
  log "(옵션) awscli/terraform 설치"
  apt-get install -y python3-pip || true
  command -v aws >/dev/null 2>&1 || pip3 install --no-cache-dir awscli || true

  if ! command -v terraform >/dev/null 2>&1; then
    pushd /tmp >/dev/null
    wget -q "https://releases.hashicorp.com/terraform/$${TF_VERSION}/terraform_$${TF_VERSION}_linux_amd64.zip"
    unzip -o "terraform_$${TF_VERSION}_linux_amd64.zip" -d /usr/local/bin
    rm -f "terraform_$${TF_VERSION}_linux_amd64.zip"
    popd >/dev/null
    terraform -version || true
  fi
}

# 실행 순서 (설치 먼저 → 마운트 나중: 마운트 실패해도 설치는 진행)
install_java17_and_utils
install_jenkins
install_docker
prepare_mount
start_jenkins_and_wait_password
install_optional_tools

log "모든 작업 완료"

