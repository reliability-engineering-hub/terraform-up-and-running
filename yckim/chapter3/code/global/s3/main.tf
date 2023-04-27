provider "aws" {
  region = "us-west-1"
}

resource "aws_s3_bucket" "terraform_state" {
	bucket = "terraform-up-and-running-state-yckim"

	# 실수로 S3가 삭제되는 것을 방지
	lifecycle {
		prevent_destroy = true
	}

	# 코드 이력을 관리하기 위한 상태 파일의 버전 관리 활성화
	versioning {
		enabled = true
	}

	# 서버 측 암호화를 활성화
	server_side_encryption_configuration {
	  rule {
		apply_server_side_encryption_by_default {
			sse_algorithm = "AES256"
		}
	  }
	}
}

resource "aws_dynamodb_table" "terraform_locks" {
	name = "terraform-up-and-running-locks"
	billing_mode = "PAY_PER_REQUEST"
	hash_key = "LockID"

	attribute {
	  name = "LockID"
	  type = "S"
	}
}

terraform {
  backend "s3" {
	bucket = "terraform-up-and-running-state-yckim"
	key = "workspace-example/terraform.tfstate"
	region = "us-west-1"
  
	dynamodb_table = "terraform-up-and-running-locks"
	encrypt = true
  }
}

resource "aws_instance" "example" {
	ami = "ami-014d05e6b24240371"
	instance_type = "t2.micro"
}