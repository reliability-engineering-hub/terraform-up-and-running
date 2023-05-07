# terraform {
#   backend "s3" {
#     # 이전에 생성한 버킷 이름으로 변경
#     bucket = "terraform-up-and-running-state-lcw"
#     key    = "stage/services/webserver-cluster/terraform.tfstate"
#     region = "ap-northeast-2"

#     # 이전에 생성한 BynamoDB Table 이름으로 변경
#     dynamodb_table = "terraform-up-and-running-locks-lcw"
#     encrypt        = true
#   }
# }

# create s3 bucket
resource "aws_s3_bucket" "terraform_state" {
  bucket = var.s3_bucket_name

  # 실수로 버킷을 삭제하는 것을 방지한다.
  lifecycle {
    prevent_destroy = true
  }

  # 코드 이력을 관리하기 위해 상태 파일의 버전 관리를 활성화한다.
  versioning {
    enabled = true
  }

  # 서버 측 암호화를 활성화 한다.
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

# create dynamodb table
resource "aws_dynamodb_table" "terraform_locks" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}