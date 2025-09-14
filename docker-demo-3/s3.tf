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

