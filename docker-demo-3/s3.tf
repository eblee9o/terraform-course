resource "aws_s3_bucket" "terraform_state" {
  count  = var.create_backend_bucket ? 1 : 0
  bucket = var.backend_bucket_name

  tags = {
    Name = "Terraform state"
  }
}

