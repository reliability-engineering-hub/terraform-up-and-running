terraform {
  backend "s3" {
    # 이전에 생성한 버킷 이름으로 변경
    bucket = "terraform-up-and-running-state-lcw"
    key    = "stage/services/webserver-cluster/terraform.tfstate"
    region = "ap-northeast-2"

    # 이전에 생성한 BynamoDB Table 이름으로 변경
    dynamodb_table = "terraform-up-and-running-locks-lcw"
    encrypt        = true
  }
}