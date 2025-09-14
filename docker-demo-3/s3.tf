########################
# s3.tf (생성 금지 가드)
########################

# 백엔드 버킷은 "참조"만 하고, 필요할 때만 생성
variable "create_backend_bucket" {
  description = "백엔드용 S3 버킷을 여기서 직접 생성할지 여부(기본: 생성 안 함)"
  type        = bool
  default     = false
}

variable "backend_bucket_name" {
  description = "이미 존재하는 S3 버킷 이름 (예: terraform-state-a2b6219)"
  type        = string
}

# 필요할 때만 생성 (대부분 환경에선 count=0 → 생성 안 함)
resource "aws_s3_bucket" "terraform_state" {
  count  = var.create_backend_bucket ? 1 : 0
  bucket = var.backend_bucket_name

  tags = {
    Name = "Terraform state"
  }
}

# 참고: 백엔드 연결은 provider/backend 파일의 아래 블록에서 수행 (여긴 생성이 아님)
# terraform {
#   backend "s3" {
#     bucket = "terraform-state-a2b6219"  # ← 실제 기존 버킷명 하드코드 권장
#     key    = "docker-demo-3/terraform.tfstate"
#     region = "eu-west-1"
#     encrypt = true
#   }
# }

