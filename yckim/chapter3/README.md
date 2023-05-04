# 테라폼 상태 관리하기
## 테라폼 상태란?
### tfstate 파일

테라폼을 실행할 때마다 테라폼은 생성한 인프라에 대한 정보를 테라폼 상태 파일에 기록합니다.

테라폼을 실행하면 실행한 기본적으로 폴더 위치에 `terraform.tfstate` 파일을 생성합니다.

tfstate 파일에는 구성파일(`.tf`) 의 테라폼 리소스가 실제 리소스 표현으로 매핑되는 내용을 기록하는 사용자 정의 JSON 형식이 포함되어 있습니다.

### tfstate 파일 저장 예시

다음은 Terraform 예시 코드입니다.

```hcl
resource "aws_instance" "example" {
	ami = "ami-0c55b159cbfafe1f0"
	instance_type = "t2.micro"
}
```

terraform apply 명령어를 실행하면 나타나는 terraform.tfstate 파일 내용의 일부입니다.

```hcl
+ resource "aws_instance" "example" {
      + ami                                  = "ami-014d05e6b24240371"
      + arn                                  = (known after apply)
      + associate_public_ip_address          = (known after apply)
      + availability_zone                    = (known after apply)
      + cpu_core_count                       = (known after apply)
      + cpu_threads_per_core                 = (known after apply)
      + disable_api_stop                     = (known after apply)
      + disable_api_termination              = (known after apply)
      + ebs_optimized                        = (known after apply)
      + get_password_data                    = false
      + host_id                              = (known after apply)
      + host_resource_group_arn              = (known after apply)
      + iam_instance_profile                 = (known after apply)
      + id                                   = (known after apply)
      + instance_initiated_shutdown_behavior = (known after apply)
      + instance_state                       = (known after apply)
      + instance_type                        = "t2.micro"
      + ipv6_address_count                   = (known after apply)
      + ipv6_addresses                       = (known after apply)
      + key_name                             = (known after apply)
      + monitoring                           = (known after apply)
      + outpost_arn                          = (known after apply)
      + password_data                        = (known after apply)
      + placement_group                      = (known after apply)
      + placement_partition_number           = (known after apply)
      + primary_network_interface_id         = (known after apply)
      + private_dns                          = (known after apply)
      + private_ip                           = (known after apply)
      + public_dns                           = (known after apply)
      + public_ip                            = (known after apply)
      + secondary_private_ips                = (known after apply)
      + security_groups                      = (known after apply)
      + source_dest_check                    = true
      + subnet_id                            = (known after apply)
      + tags_all                             = (known after apply)
      + tenancy                              = (known after apply)
      + user_data                            = (known after apply)
      + user_data_base64                     = (known after apply)
      + user_data_replace_on_change          = false
      + vpc_security_group_ids               = (known after apply)
    }
```

테라폼은 이 JSON 형식을 통해 생성해야할 인스턴스의 정보를 알게됩니다.

테라폼을 실행할때마다 AWS에서 이 EC2 인스턴스의 최신 상태를 가져와서 테라폼의 구성과 비교하여 어느 변경사항에 적용해야 하는지 알 수 있습니다.

즉, `terraform plan` 명령의 출력 결과는 상태 파일의 ID를 통해 발견된 테라폼 코드와 실제 인프라 간의 차이를 의미합니다.

### terraform.tfstate 파일 관리

개인 프로젝트에서 테라폼을 사용하는 경우 로컬 컴퓨터의 단일 terrafrom.state 파일에 상태를 저장하는 것이 좋습니다.

단, 팀단위로 사용할때 다음과 같은 문제를 겪을 수 있습니다.

- 상태 파일을 저장하는 공유 스토리지
    - 테라폼을 사용하여 인프라를 업데이트하려면 각 팀원이 동일한 테라폼 상태 파일에 액세스해야 합니다.
- 상태 파일 잠금
    - 상태 데이터가 공유되자마자 잠금(locking)이라는 새로운 문제가 발생합니다.
    - 잠금 기능 없이 팀원이 동시에 테라폼을 실행시키는 경우 여러 테라폼 프로세스가 상태 파일을 동시에 업데이트하여 충돌을 일으킬 수 있습니다.
    - 이러한 경쟁 상태에 처하면 데이터가 손실되거나 상태파일이 손상될 수 있습니다.
- 상태 파일 격리
    - 인프라를 변경할 때는 다른 환경으로 격리하는 것이 가장 좋습니다.
    - 예를 들어 테스트 또는 스테이징 환경을 변경할 때 실수로 프로덕션 환경이 중단되는 경우는 없는지 확인해야 합니다.
    - 그러나 모든 인프라가 동일한 테라폼 상태 파일에 정의되어 있다면 변경 사항을 격리하기 힘듭니다.


## 상태 파일 공유
### 버전관리 시스템으로 관리하기

여러명의 팀원이 파일에 공통으로 액세스할 수 있게 하는 가장 일반적인 방법은 파일을 깃과 같은 버전 관리 시스템에 두는 것입니다.

그러나 테라폼 상태 파일을 버전 관리 시스템에 저장하는 것은 다음과 같은 이유 때문에 부적합합니다.

- 수동 오류
    - 테라폼을 실행하기 전에 최신 변경 사항을 가져오거나 실행하고 나서 푸시하는 것을 잊기 쉽습니다.
    - 팀의 누군가가 이전 버전의 상태 파일로 테라폼을 실행하고, 그 결과 실수로 이전 버전으로 롤백하거나 이전에 배포된 인프라를 복제하는 문제가 발생할 수 있습니다.
- 잠금
    - 대부분의 버전 관리 시스템은 여러 명의 팀 구성원이 동시에 하나의 상태 파일에 terraform apply 명령을 실행하지 못하게 하는 잠금 기능을 제공하지 않습니다.
- 시크릿
    - 테라폼 상태 파일의 모든 데이터는 평문(plain text)으로 저장되는데 특정 테라폼 리소스에 중요한 데이터를 저장해야 할 때 문제가 발생합니다.
    - 예를 들어 aws_db_instance 리소스를 사용하여 데이터베이스를 만드는 경우 테라폼은 데이터베이스의 사용자 이름과 비밀번호 같은 중요한 데이터를 평문으로 저장하는 것은 버전 관리나 보안 측면에도 적절하지 않습니다.

### 추천하는 상태 파일 공유 방법

상태 파일 공유 스토리지를 관리하는 가장 좋은 방법은 테라폼에 내장된 원격 백엔드 기능을 사용하는 것입니다.

테라폼 백엔드는 테라폼이 상태를 로드하고 저장하는 방법을 결정합니다.

기본 백엔드는 로컬 백엔드로써 로컬 디스크에 상태 파일을 저장합니다.

원격 백엔드를 사용하면 상태 파일을 원격 공유 저장소에 저장할 수 있습니다.

아마존 S3와 애저 스토리지, 구글 클라우드 스토리지, 하시코프 테라폼 클라우드, 테라폼 프로, 테라폼 엔터프라이즈 등 다양한 원격 백엔드가 지원됩니다.

원격 백엔드는 앞서 말한 3가지 문제를 모두 해결할 수 있습니다.

- 수동오류
    - 원격 백엔드를 구성하면 테라폼은 plan이나 apply 명령을 실행할 때마다 해당 백엔드에서 상태 파일을 자동으로 로드합니다.
    - apply 명령을 실행한 후에는 상태 파일을 백엔드에 자동 저장하므로 수동 오류가 발생하지 않습니다.
- 잠금
    - 대부분의 원격 백엔드는 기본적으로 잠금 기능을 지원합니다.
    - terraform apply 명령을 실행하면 테라폼은 자동으로 잠금을 활성화하며, 다른 사람이 apply 명령을 완료할 때까지 대기합니다.
        - --lock-timeout=<TIME> 매개변수를 사용하면 apply 명령을 실행할 때 잠금이 해제되기까지 테라폼이 얼마나 대기하도록 할지 설정할 수 있습니다.
- 시크릿
    - 대부분의 원격 백엔드는 기본적으로 데이터를 보내거나 상태 파일을 저장할 때 암호화하는 기능을 지원합니다.
    - 액세스 키와 같은 민감정보를 암호화하여 저장하기 때문에 평문으로 저장하는 것보다 안전하게 관리할 수 있습니다.

### S3로 원격 백엔드 사용하기

테라폼을 AWS와 함께 사용하는 경우 원격 백엔드로는 아마존이 관리하는 파일 저장소인 아마존 S3가 가장 적합니다.

S3를 사용하면 다음과 같은 장점이 존재합니다.

- 관리형 서비스이므로 추가 인프라를 배포하고 관리할 필요가 없습니다.
- 99.9999999%의 내구성과 99.99% 가용성을 제공하도록 설계되었으므로 데이터 손실 또는 서비스 중단을 걱정할 필요가 없습니다.
- 암호화를 지원하므로 상태 파일에 민감한 데이터를 저장할 때 안전성을 높입니다.
    
    S3 버킷에 액세스할 수 있는 팀원은 상태 파일을 암호화되지 않은 형태로 볼 수 있으므로 여전히 부분적인 솔루션이지만 최소한 전송 중인 데이터는 암호화할 수 있습니다.
    
- 아마존 DynamoDB를 통한 잠금 기능을 지원합니다.
- 버전 관리를 지원하므로 상태 파일의 수정 사항이 모두 저장됩니다. (이를 통해 롤백 가능)
- 대부분의 테라폼 기능을 프리티어로 쉽게 사용할 수 있으므로 비용이 저렴합니다.

### S3 원격 백엔드 예제

먼저 원격 상태 스토리지로 사용하기 위해 S3 버킷을 생성해야 합니다.

다음과 같이 AWS를 공급자로 설정합니다.

```terraform
provider "aws" {
  region = "us-west-1"
}
```

다음으로 aws_s3_bucket 리소스를 사용하여 S3 버킷을 생성합니다.

```
provider "aws" {
  region = "us-west-1"
}

resource "aws_s3_bucket" "terraform_state" {
	bucket = "terraform-up-and-running-state"

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
```

위의 코드는 다음과 같은 4가지 인수를 설정합니다.

- bucket
  - S3의 버킷 이름을 지정합니다.
  - S3 버킷 이름은 AWS의 다른 고객과 겹치지 않도록 고유해야 합니다.
- prevent_destroy
  - 중요한 리소스를 삭제하지 않도록 막아주는 수명 주기 설정입니다.
  - true로 설정할 경우 테라폼이 오류와 함께 종료되어 삭제를 막아줄 수 있습니다.
- versioning
  - S3 버킷에 버전 관리를 활성화하여 버킷의 파일이 업데이트 될 때마다 새버전을 만들도록 합니다.
  - 이를 통해 언제든지 새로운 버전으로 변경할 수 있습니다.
- server_side_encryption_configuration
  - 이 부분은 S3 버킷에 기록된 모든 데이터에 서버 측 암호화를 설정합니다.
  - 이를 통해 상태 파일이나 시크릿을 암호화할 수 있습니다.


### DynamoDB

이제 잠금을 하기 위해 DynamoDB 테이블을 설정해야 합니다.

먼저 DynamoDB를 만들기전에 알아봅시다.

DynamoDB는 다음과 같은 특징을 가지고 있습니다.

- DynamoDB는 아마존의 분산형 key-value 저장소입니다.
- 분산 잠금 시스템에 필요한 강력한 읽기 일관성 및 조건부 쓰기를 지원합니다.
- 아마존이 완벽하게 관리하므로 직접 운영할 필요가 없습니다.


### 테라폼에서 DynamoDB 사용하기

테라폼에서 DynamoDB를 잠금에 사용하려면 LockID라는 기본키가 있는 DynamoDB 테이블을 생성해야 합니다.

`aws_dynamodb_table` 리소스를 사용하여 테이블을 생성할 수 있습니다.

```
resource "aws_dynamodb_table" "terraform_locks" {
	name = "terraform-up-and-running-locks"
	billing_mode = "PAY_PER_REQUEST"
	hash_key = "LockID"

	attribute {
	  name = "LockID"
	  type = "S"
	}
}
```

terraform apply 명령을 통해 작성한 코드를 실행하면 정상적으로 실행되는 것을 볼 수 있습니다.

### 테라폼 상태 파일 S3에 추가하기

모든 리소스를 배포 완료하더라도 테라폼 상태 파일은 여전히 로컬 디스크에 저장되는 것을 볼 수 있습니다.

테라폼을 S3 버킷에 상태를 저장하고 싶다면 테라폼 코드 내에 backend 구성을 설정해야 합니다.

이것은 테라폼 자체를 구성하는 것이므로 terraform 블록에 다음과 같이 작성합니다.
```
terraform {
	backend "<BACKEND_NAME>" {
		[CONFIG...]
	}
}
```

여기서 BACKEND_NAME은 S3 같은 백엔드의 이름이며 CONFIG는 사용할 S3 버킷의 이름과 같은 `백엔드에 고유한 하나 이상의 인수로 구성`됩니다.

다음은 코드 예시입니다.
```
terraform {
  backend "s3" {
	bucket = "terraform-up-and-running-state-yckim"
	key = "global/s3/terraform.tfstate"
	region = "us-west-1"
  
	dynamodb_table = "terraform-up-and-running-locks"
	encrypt = true
  }
}
```

설정을 하나씩 살펴보면 다음과 같습니다.

- bucket
  - 사용할 S3 버킷의 이름입니다.
- key
  - 테라폼 상태 파일을 저장할 S3 버킷 내의 파일 경로입니다.
- region
  - S3 버킷이 있는 AWS 리전입니다.
- dynamodb_table
  - 잠금에 사용할 DynamoDB 테이블입니다.
- encrypt
  - 이 부분을 true로 설정하면 테라폼 상태가 S3 디스크에 저장될 때 암호화됩니다.
  - 우리는 이미 S3 버킷 자체에서 기본 암호화를 설정했기 때문에 데이터가 항상 암호화되지만 확실하게 암호화하도록 설정하는 두 번째 방법입니다.

### 테라폼 백엔드 구성을 위한 추가 명령
테라폼이 S3 버킷에 상태 파일을 저장하도록 지시하려면 terraform init 명령을 다시 실행해야 합니다.

이 명령은 공급자 코드를 다운로드할 수 있을 뿐만 아니라 테라폼의 백엔드를 구성할수도 있습니다.

나중에 살펴보겠지만 이 명령은 또 다른 용도로도 사용됩니다.
게다가 init 명령은 멱등성이 있으므로 계속해서 실행해도 안전합니다.

```
terraform init
```

이제 명령을 실행하면 S3 버킷에 테라폼 상태 파일이 저장되는 것을 알 수 있습니다.

### 백엔드가 잘 동작하는지 확인해보기

백엔드가 활성화되면 테라폼은 명령을 실행하기 전에 이 S3 버킷에서 최신 상태를 자동으로 가져옵니다.

그리고 명령을 실행한 후에는 최신 상태를 S3 버킷으로 자동 푸시합니다.

다음과 같은 코드를 추가하여 확인해봅시다.

```
# s3 ARN 출력
output "s3_bucket_arn" {
	value = aws_s3_bucket.terraform_state.arn
	description = "The ARN of the S3 bucket"
}

# dynamodb 테이블 이름 출력
output "dynamodb_table_name" {
	value = aws_dynamodb_table.terraform_locks.name
	description = "The name of the DynamoDB table"
}
```

이제 terraform apply 명령을 다시 실행 시키면 상태 파일을 잠금을 실행하고 실행 후에 잠금을 해제하는 것을 확인할 수 있습니다.

그리고 S3 콘솔을 확인해보면 새로운 버전의 `tfstate` 파일이 저장된 것을 볼 수 있습니다.

즉, 테라폼은 S3에 상태 데이터를 자동으로 푸시하거나 가져오고 S3가 상태 파일의 모든 변경사항을 저장합니다.

따라서 문제가 발생하는 경우 이전 버전으로 롤백하기 쉬워집니다.

## 테라폼 백엔드의 단점

### 테라폼 상태를 저장할 S3 버킷을 생성하는 순서가 애매하다.

테라폼 상태파일을 S3로 관리할 경우 다음과 같은 작업을 진행해야 합니다.
1. 테라폼 코드를 작성하여 S3 버킷 및 DynamoDB 테이블을 생성하고 해당 코드를 로컬 백엔드와 함께 배포
2. 테라폼 코드로 돌아가서 원격 backend 구성을 추가합니다.
   - 새로 생성된 S3 버킷과 DynamoDB 테이블을 사용하고 terraform init명령을 실행하여 로컬 상태를 S3에 복사합니다. 

S3 버킷과 DynamoDB 테이블을 삭제하려면 이 단계를 반대로 수행해야 합니다.
1. 테라폼 코드로 이동하여 backend 구성을 제거한다음 terraform init 명령을 재실행하여 테라폼 상태를 로컬 디스크에 다시 복사합니다.
2. terraform destroy 명령을 실행하여 S3 버킷 및 DynamoDB 테이블을 삭제합니다.

이러한 2단계 프로세스가 좀 어색합니다.

하지만, 단일 S3 버킷과 DynamoDB 테이블을 테라폼 코드 전체에 걸쳐 공유할 수 있기 때문에 한번만 수행하면 되기 때문에 크게 부담은 없습니다.

### 테라폼의 backend 블록에서는 변수나 참조를 사용할 수 없다.

테라폼의 backend 블록에서는 변수나 참조를 사용할 수 없습니다.

이로 인해 다음 코드는 동작하지 않습니다.
```
terraform {
	backend "s3" {
		bucket = var.bucket
		region = var.region
		dynamodb_table = var.dynamodb_table
		key = "example/terraform.tfstate"
		encrypt = true
	}
}
```

즉, S3 버킷 이름, 리전, DynamoDB 테이블 이름 같은 변수들을 모두 수동으로 복사해서 붙여 넣어야 합니다.

심지어 key 값을 복사해서 붙여넣어야 안 되고 배포하는 모든 테라폼 모듈마다 고유한 key를 확보해서 실수로 다른 모듈의 상태를 덮어쓰지 않도록 해야 합니다.

복사해서 붙여넣기와 수동 변경 작업을 자주 하면 에러가 발생하기 쉽습니다.
특히 다중 환경에서 여러 테라폼 모듈을 배포하고 관리하는 경우 에러가 발생하기 쉽습니다.

### 부분 구성의 장점을 활용하기

부분 구성을 사용하면 이러한 문제를 최소화할 수 있습니다.

테라폼 코드의 backend 구성에서 매개 변수를 생략하고 대신 terraform init을 호출할 때 -backend-config 인수를 통해 매개변수를 전달하는 것입니다.

예를 들어 bucket 및 region 같은 반복되는 백엔드 인수를 backend.hcl이라는 별도의 파일로 추출할 수 있습니다.

```
# backend.hcl
bucket = "terraform-up-and-running-state"
region = "us-west-1"
...
```

모듈마다 서로 다른 key 값을 설정해야 하기 때문에 key 매개변수만 테라폼 코드에 남길 수 있습니다.

```
terraform {
	backend "s3" {
		key = "example/terraform.tfstate"
	}
	
}
```

부분적으로 구성한 것들을 모두 결합하려면 -backend-config 인수와 함께 terraform-init 명령을 실행합니다.

```
terraform init -backend-config=backend.hcl
```

테라폼은 backend.hcl의 구성을 테라폼 코드의 구성과 병합하여 모듈에서 사용하는 전체 구성을 생성합니다.

### 테라그런트로 관리하기

또 다른 옵션으로 테라폼의 몇 가지 단점을 보완해주는 테라그런트를 사용하는 것입니다.

테라그런트는 버킷 이름, 리전, DynamoDB 테이블 이름 같은 모든 기본 백엔드 설정을 하나의 파일에 정의하고 key 매개 변수를 모듈의 상대 경로에 설정하여 backend 구성을 반복하지 않도록 도와줍니다.

## 상태 파일 격리

### 테라폼 상태를 격리하기

원격 백엔드와 잠금을 같이 사용하면 협업에는 문제가 발생하지 않습니다.

테라폼을 처음 사용하기 시작하면 모든 인프라를 하나의 테라폼 파일에 관리하고 싶을 수 있습니다.

하지만 이런식으로 관리할 경우 테라폼 상태가 하나의 파일에 저장되므로 실수로 전체를 날려 버릴수도 있습니다.

예를 들어, 새 버전의 앱을 배포하려고 준비중일 때 운영환경에서 동작하는 애플리케이션에 중단이 발생할 수 있습니다.

또는 잠금을 사용하지 않았거나 불의의 테라폼 버그가 발생해 전체 파일이 손상될 수 있으며 결국 모든 환경의 인프라가 손상됩니다.

분리된 환경을 갖춘다는 것은 하나의 환경을 다른 환경으로 부터 격리한다는 것이고 따라서 `단 하나의 테라폼 구성안에서 모든 환경을 관리하고 있다면 격리 상태를 깨트리게 됩니다.`

이런 상황을 방지하기 위해 환경별로 테라폼을 파일을 분리하는 것이 좋습니다.

### 상태 파일을 격리하는 방법

하나의 환경에 문제가 발생하더라도 다른 환경에 문제가 생기지 않도록 상태파일을 격리하는 방법은 다음과 같습니다.
- 작업 공간을 통한 격리
  - 동일한 구성에서 빠르고 격리된 테스트 환경에 유용합니다.
- 파일 레이아웃을 이용한 격리
  - 보다 강력하게 분리해야 하는 운영 환경에 적합합니다.

### 작업 공간을 통한 격리

테라폼 작업 공간을 통해 테라폼 상태를 별도의 이름에 가진 여러 개의 공간에 저장할 수 있습니다.

테라폼은 default라는 기본 작업 공간에서 시작하며, 작업 공간을 따로 지정하지 않으면 기본 작업 공간을 사용합니다.

새 작업 공간을 만들거나 작업 공간을 전환하려면 terraform workspace 명령을 사용합니다.

하나의 EC2 인스턴스를 배포하는 테라폼 코드에서 작업 공간을 시험해 보겠습니다.

```
resource "aws_instance" "example" {
	ami = "ami-014d05e6b24240371"
	instance_type = "t2.micro"
}
```

이 장의 앞 부분에서 생성한 S3 버킷 및 DynamoDB 테이블을 사용하여 백엔드 설정을 구성합니다.

key 값은 workspace-example/terraform.tfstate로 설정합니다.

```
terraform {
  backend "s3" {
	bucket = "terraform-up-and-running-state-yckim"
	key = "workspace-example/terraform.tfstate"
	region = "us-west-1"
  
	dynamodb_table = "terraform-up-and-running-locks"
	encrypt = true
  }
}
```

이 배포 작업의 상태 정보는 기본 작업 공간에 저장됩니다.

terraform workspace show 명령을 실행하여 현재 작업 공간을 확인할 수 있습니다.

```
default
```

기본 작업 공간은 key 구성을 통해 지정한 위치에 상태를 저장합니다.

s3 버킷을 살펴보면 workspace-example 폴더에 terraform.tfstate파일이 있습니다.

### 새로운 작업 공간 만들기

terraform workspace new 명령을 사용하면 새로운 작업 공간을 만들 수 있습니다.

```
terraform workspace new example1
```

작업 공간이 새로 만들어진 상태에서 terraform plan을 실행시키면 테라폼은 완전히 새로운 EC2 인스턴스를 처음부터 만들려고 합니다.

왜냐하면 기본 작업 공간과 example1 작업 공간의 상태 파일이 서로 분리되었기 때문에 인프라 자원들이 생성되지 않은 것으로 판단하기 때문입니다.

terraform apply 명령을 사용하면 해당 인스턴스들이 띄워진 것을 확인할 수 있습니다.

### env:
작업 공간을 나눈 후 S3를 확인해보면 `env:` 라는 폴더를 확인할 수 있습니다.

`env:` 폴더안에는 생성한 작업공간의 이름이 적혀있습니다.

```
workspace1
```

각 작업 공간 내에서 테라폼은 backend 구성에서 지정한 key를 사용합니다.

작업 공간마다 별도의 상태 파일이 있으므로 example1과 example2 작업 공간을 사용하면 테라폼은 각각의 작업공간에 terraform.state 파일을 저장합니다.

이 처럼 작업 공간을 나누는 기능은 코드 리팩터링을 시도하는 것 같이 이미 배포되어 있는 인프라에 영향을 주지 않고 테라폼 모듈을 테스트할 때 유용합니다.

### terraform.workspace
terraform.workspace 표현식을 사용하여 작업 공간 이름을 읽으면 현재 작업 공간을 기준으로 해당 모듈의 동작 방식을 변경할 수도 있습니다.

예를 들어 테스트 비용을 절감하기 위해 기본 작업 공간에서 인스턴스 유형을 t2.medium으로 설정하고 다른 모든 작업 공간에서 t2.micro로 지정할 수도 있습니다.

```
resouce "aws_instance" "example" {
	ami = "ami-014d05e6b24240371"
	instance_type = terraform.workspace == "default" ? "t2.medium" : "t2.micro"
}
```

### 테라폼 작업 공간의 단점

테라폼 작업 공간을 사용하면 더 빠르게 가동하고 분해할 수 있지만 몇 가지 단점이 있습니다.

- 모든 작업 공간의 상태 파일은 동일한 백엔드에 저장됩니다.
  
  즉 모든 작업 공간이 같은 인증 매커니즘을 사용합니다.

  이는 작업 공간을 이용하는 격리방식이 환경을 분리하는데 적합하지 않은 주요한 이유 중 하나입니다.

- terraform workspace 명령을 실행하지 않으면 코드나 터미널에 작업 공간에 대한 정보가 표시되지 않습니다.
  
  코드를 탐색할 때 한 작업 공간에 배치된 모듈은 다른 모든 작업 공간에 배치된 모듈과 정확히 동일합니다.

  그렇기 때문에 인프라를 제대로 파악할 수 없어서 유지 관리가 더욱 어려워집니다.

- 이전 항목 2개를 결합하면 작업 공간에 오류가 발생할 수 있습니다.

	어떤 작업 공간에 있는지 보이지 않기 때문에 현재 사용중인 작업 공간이 어느 것인지 잊어버리기 쉽습니다.

	또한 스테이징 작업 공간이 아닌 프로덕션 작업 공간에서 terraform destroy 명령어를 실행하는 것 같이 실수로 작업 공간을 변경할 수도 있습니다.

	모든 작업 공간에 동일한 인증 매커니즘을 사용하면 이와 같은 오류에서 보호할 방법이 없습니다.

### 파일 레이아웃을 이용한 격리

환경을 완전히 격리하려면 다음 작업을 수행해야 합니다.

- 각 테라폼 구성 파일을 분리된 폴더에 넣습니다.
	- 예를 들어 스테이징 환경에 대한 모든 구성은 stage 폴더에, 프로덕션 환경의 모든 구성은 prod 폴더에 넣습니다.

- 서로 다른 인증 매커니즘과 액세스 제어를 사용하여 각 환경에 서로 다른 백엔드를 구성합니다.
  - 예를 들어 각 환경은 각각 분리된 S3 버킷은 백엔드로 사용하는 별도의 AWS 계정에 있을 수 있습니다.

분리된 폴더를 사용하는 접근 방식을 사용하면 다음과 같은 장점이 있습니다.

- 어떤 환경에 배포할지 훨씬 명확해집니다.
- 각기 다른 인증 매커니즘을 사용하는 별도의 상태 파일을 사용하므로, 한 환경에서 문제가 발생하더라도 다른 환경에 영향을 줄 가능성이 크게 줄어듭니다.

### 구성 요소 수준으로 격리 수준을 높이기

구성 요소란 `일반적으로 함께 배포되는 일관된 리소스 집합`을 의미합니다.

예를 들어, VPC, 서브넷, 라우팅 규칙, 네트워크 ACL 등의 인프라의 기본 네트워크 토폴로지를 설정하고 나면 몇 달에 한번씩만 수정하는 상황이 올 수 있습니다.

반면에 웹서버는 하루에도 몇 번 씩 배포할 수 있습니다.

VPC 구성 요소와 웹 서버 구성 요소를 모두 동일한 테라폼 구성 세트에서 관리하는 경우 하루에도 여러 번 전체 네트워크 토폴로지가 손상될 수 있습니다.

따라서 스테이징, 프로덕션 등 각 환경과 VPC, 서비스, 데이터베이스 같은 각 구성 요소를 별도의 테라폼 폴더 혹은 별도의 상태 파일에서 사용하는 것을 권장합니다.

### 테라폼 프로젝트의 파일 레이아웃 예시

일반적으로 테라폼 프로젝트는 다음과 같은 파일 레이아웃을 보여줍니다.

```
.
├── global
│   ├── iam
│   └── s3
├── mgmt
│   ├── services
│   │   ├── bastion-host
│   │   └── jenkins
│   └── vpc
├── prod
│   ├── data-storage
│   │   ├── mysql
│   │   └── redis
│   ├── services
│   │   ├── backend-app
│   │   └── frontend-app
│   └── vpc
└── stage
    ├── data-storage
    │   ├── mysql
    │   └── redis
    ├── services
    │   ├── backend-app
    │   └── frontend-app
    └── vpc

```

최상위에는 각 환경마다 별도의 폴더가 존재합니다.

- stage
  - 테스트 환경과 같은 프로덕션 워크로드 환경
- prod
  - 사용자용 프로덕션 워크로드 환경
- mgmt
  - 배스천 호스트, 젠킨스와 같은 데브옵스 도구 환경
- global
  - s3, IAM과 같이 모든 환경에서 사용되는 리소스를 배치할 수 있는 장소

각 환경에는 구성 요소마다 별도의 폴더가 있습니다.

프로젝트마다 구성요소가 다르지만 일반적인 구성 요소는 다음과 같습니다.

- vpc
  - 해당 환경을 위한 네트워크 토폴로지
- services
  - 루비 온 레일즈 프런트엔드 또는 스칼라(Scala) 백엔드 같이 해당 환경에서 서비스되는 애플리케이션 또는 마이크로서비스입니다.
  - 각 앱은 자체 폴더에 위치하여 다른 모든 앱과 분리할 수 있습니다.
- data-storage
  - MySQL 또는 레디스와 같은 해당 환경에서 실행할 데이터 저장소입니다.
  - 각 데이터 저장소는 자체 폴더에 상주하여 다른 모든 데이터 저장소와 분리할 수 있습니다.

각 구성 요소에는 다음과 같은 명명 규칙에 따라 구성되는 실제 테라폼 구성 파일이 존재합니다.

- variables.tf
  - 입력 변수
- outputs.tf
  - 출력 변수
- main.tf
  - 리소스

테라폼을 실행할 때 확장명이 .tf면 원하는 파일 이름을 사용할 수 있습니다.

일관되고 예측 가능한 명명 규칙을 사용하면 코드를 보다 쉽게 찾아볼 수 있습니다.

물론, 특정 규모가 커진다면 기능별로 iam.tf, s3.tf 등으로 별도의 파일로 분리될 수 있지만 이는 별도의 더 작은 모듈로 나누어야 한다는 신호일 수 있습니다.

### 작성한 파일 패키지 구조 변경

지금까지 작성한 파일을 테라폼 스타일로 구조를 변경해봅시다.

```
.
├── global
│   └── s3
│       ├── main.tf
│       └── outputs.tf
├── stage
│   └── services
│       └── webserver-cluster
│           ├── main.tf
│           ├── outputs.tf
│           └── variables.tf
```

```
🚨 패키지 구조를 변경할 때 .terraform 폴더도 같이 옮겨 주어야 합니다.
```

### 파일 레이아웃의 장단점

파일 레이아웃 방식을 사용할 경우 다음과 같은 장점이 존재합니다.
- 코드를 쉽게 탐색할 수 있다.
- 각 환경에 어떠한 구성 요소가 배포되었는지 정확하게 알 수 있다.
- 환경 간, 그리고 환경 내 구성 요소 간 적절한 격리를 통해 문제가 발생할 경우 전체 인프라에 영향을 주지 않고 손상을 최소합니다.

파일 레이아웃 방식을 사용할 경우 다음과 같은 단점이 존재합니다.
- 한번의 명령으로 전체 인프라를 만들지 못합니다.
  - 단, 테라그런트를 사용하는 경우 apply-all 명령을 사용하려 자동화할 수 있습니다.
- 리소스 종속성을 사용하기 어렵습니다.
  - 테라폼 코드가 다른 폴더에 있는 경우 다른 폴더의 리소스에 직접 액세스할 수 없습니다. 
  - `terraform_remote_state` 를 이용하면 이와 같은 문제를 해결할 수 있습니다.


## terraform_remote_state 데이터 소스

### terraform_remote_state 란

terraform_remote_state 라는 데이터 소스를 이용하면 테라폼 구성 세트에 완전한 읽기 전용으로 저장된 테라폼 상태 파일을 가져올 수 있습니다.

예를 들어, 웹 서버 클러스터가 MySQL 데이터베이스와 통신해야 한다고 가정해봅시다.

웹 서버 클러스터는 MySQL 데이터베이스보다 훨씬 자주 배포할 것이므로 배포 과정에서 실수로 데이터베이스를 손상시키고 싶지 않다면 같은 위치에 정의하는 것을 피해야 합니다.

먼저 다음과 같은 데이터베이스 리소스가 존재한다고 가정해봅시다.
```
provider "aws" {
  region = "us-west-1"
}

resource "aws_db_instance" "example" {
	identifier_prefix = "terraform-up-and-running"
	engine = "mysql"
	allocated_storage = 10
	instance_class = "db.t2.micro"
	name = "example_database"
	username = "admin"
	# password 처리 방안?
	password = ""
}
```

위의 테라폼 파일의 문제는 패스워드를 작성해야 한다는 것입니다.

패스워드 정보는 다른 사용자에게 노출되면 안 되는 정보이므로 평문으로 입력하면 안됩니다.

### 시크릿을 테라폼 리소스로 전달하기

이를 해결하기 위한 방법은 2가지가 존재합니다.

첫 번째 방법은 테라폼 데이터 소스를 사용하여 시크릿 저장소에ㅐ서 정보를 읽어오는 것입니다.

예를 들어, 데이터베이스 패스워드 같은 시크릿은 AWS 시크릿 매니저에 저장할 수 있습니다.

AWS 시크릿 매니저 UI는 민감한 데이터를 저장할 수 있도록 AWS에서 특별한 제공하는 관리형 서비스입니다.

AWS 시크릿 매니저 UI를 사용하여 시크릿을 저장한 다음 aws_secretmanager_secret_version 데이터 소스를 사용하여 테라폼 코드에서 시크릿 값을 다시 읽을 수 있습니다.

```
# main.tf
provider "aws" {
  region = "us-west-1"
}

resource "aws_db_instance" "example" {
	identifier_prefix = "terraform-up-and-running"
	engine = "mysql"
	allocated_storage = 10
	instance_class = "db.t2.micro"
	name = "example_database"
	username = "admin"
	password = data.aws_secretmanager_secret_version.db_password.secret_string
}

data "aws_secretmanager_secret_version" "db_password" {
	secret_id = "mysql-master-password-stage"
}
```

다음은 다양한 공급자가 지원하는 시크릿 저장소와 데이터 소스입니다.

- AWS 시크릿 매니저와 aws_secretmanager_secret_version
- AWS 시스템 관리자 매개변수 저장소와 aws_ssm_parameter 데이터 소스
- AWS KMS와 aws_kms_secrets 데이터 소스
- 구글 클라우드 KMS와 google_kms_secrets 데이터 소스
- 마이크로소프트 애저 키 볼트와 azurem_key_valut_secret 데이터 소스
- 해시코프 볼트 및 vault_generic_secrets 데이터 소스

시크릿을 테라폼 리소스로 전달하는 방법은 시크릿 값을 원패스워드, 라스트 패스 또는 macOS의 키체인 접근과 같은 테라폼 외부에서 관리하고 환경변수를 통해 테라폼에 전달하는 것입니다.

```
variable "db_password" {
  description = "The password for the database"
  type = string
}
```

### 시크릿 값은 항상 테라폼 상태에 저장된다.

시크릿 저장소 또는 환경변수에서 시크릿 값을 읽는 것은 좋은 방법입니다.

하지만 시크릿 값을 어떻게 읽던지 테라폼 리소스에 시크릿 값을 인수로 전달하면 해당 시크릿 값은 테라폼 상태 파일에 평문으로 저장됩니다.

이는 테라폼의 약점이며 해결방법도 없습니다.
그러므로 항상 암호화를 사용하는 등 상태 파일을 저장할 때 특히 주의해야 합니다.

### 테라폼 상태 등록하기

작성한 테라폼 db 리소스 파일을 포함하여 tfstate 파일을 s3에 올리면 다음과 같이 terraform_remote_state 데이터 소스를 이용하여 db 데이터를 읽어올 수 있습니다.

```
data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
	bucket = "terraform-up-and-running-state-yckim"
	key = "stage/data-stores/mysql/terraform.tfstate"
	region = "us-west-1"
   }
}
```

다음과 같은 형식으로 참조하여 데이터베이스의 출력 변수를 읽어올 수 있습니다.

```
data.terraform_remote_state.<NAME>.outputs.<ATTRIBUTE>
```

예를 들어 다음과 같이 shell script를 사용하여 db url을 얻을 수 있습니다.

```
user_data = << EOF
	#!/bin/bash
	echo "${data.terraform_remote_state.db.outputs.address}"
	EOF
```

### 사용자 스크립트 외부화하기

테라폼 코드에 shell script를 추가하면 코드도 복잡해지고 관리하기 어려워집니다.

테라폼에서는 배시 스크립트를 외부화하기 위해 내장 함수와 template_file 데이터 소스를 사용합니다.

테라폼에는 표현식을 사용하여 실행할 수 있는 여러 내장 함수가 존재합니다.

```
function_name(...)
```

예를 들어 format 함수는 다음과 같이 사용합니다.

```
format(<FMT>, <ARGS>, ...)

format("%.3f", 3.141592)
```

terraform console 명령을 사용하면 이러한 테라폼 함수를 테스트해볼 수 있습니다.

### 테라폼 함수 file
테라폼 함수 중 file 함수를 사용하면 특정 파일을 읽고 내용을 문자열로 반환할 수 있습니다.

예를 들어 user-data.sh 파일의 내용을 반환하려면 다음과 같이 작성하면 됩니다.

```
file("user-data.sh")
```

그러나 웹 서버 클러스터의 스크립트는 서버 포트, 데이터베이스 주소 등 테라폼에 정의한 동적인 데이터를 필요로 한다는 문제점이 존재합니다.

file 함수만 사용해서는 이러한 문제를 해결할 수 없습니다.

### template_file

테라폼의 template_file 데이터 소스를 사용하면 이러한 문제를 해결할 수 있습니다.

template_file 데이터 소스는 다음과 같은 형식으로 사용할 수 있습니다.

```
data "template_file" "지정할 이름" {
	template = 랜더링할 문자열

	vars = {
		랜더링할 key = 치환할 value
		...
	}
}
```

다음은 예시 코드입니다.
```
data "template_file" "user-data" {
  template = file("user-data.sh")

  vars = {
	"db_address" = data.terraform_remote_state.db.outputs.address
  }
}
```

user-data.sh 파일은 다음과 같이 환경변수 처리 해주면 db 주소가 불러와지는 것을 알 수 있습니다.

```
#!/bin/bash

echo ${db_address}
```

그리고 파일을 외부로 추출했기 때문에 해당 파일을 테스트하는 코드를 작성할 수 있다는 장점도 존재합니다.