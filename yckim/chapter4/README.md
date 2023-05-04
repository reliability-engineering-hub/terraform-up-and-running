# 테라폼 모듈로 재사용 가능한 인프라 생성하기

### 서버 환경은 여러개 존재할 수 있다.

실제 애플리케이션을 만들고 배포하려면 운영 환경 뿐만아니라 개발 환경, 스테이징 환경 등 다양한 환경이 필요할 수 있습니다.

그리고 각각의 환경별로 더 적은 수의 서버나 작은 서버로 테스트할 수 있기 때문에 각기 다른 리소스 정의가 필요합니다.

### 테라폼 모듈을 통한 중복 제거
일반적으로 프로그래밍 언어들은 하나의 함수를 작성하면 해당 함수를 호출하여 어디서나 재사용할 수 있도록 관리됩니다.

테라폼도 마찬가지로 테라폼 모듈에 넣고 전체 코드의 여러 위치에서 해당 모듈을 재사용할 수 있습니다.

테라폼 모듈은 코드를 재사용할 수 있고 유지 관리하기 쉬우며, 테스트 코드를 작성할 수 있게 해주는 핵심 요소입니다.

## 모듈의 기본

디렉터리에 존재하는 모든 테라폼 구성 파일은 모듈입니다.

### 테라폼 모듈 만들기
지금 까지 만들어본 파일들을 재사용 가능한 모듈로 변경해봅시다.

먼저, modules라는 패키지를 만들고 작성한 코드를 modules/services/webserver-cluster로 이동합시다.

```
└── code
    ├── global
    │   └── s3
    │       ├── main.tf
    │       └── outputs.tf
    ├── modules
    │   └── service
    │       └── webserver-cluster
    │           ├── main.tf
    │           ├── outputs.tf
    │           ├── user-data.sh
    │           └── variables.tf
    └── stage
        ├── data-stores
        │   └── mysql
        │       ├── main.tf
        │       ├── outputs.tf
        │       └── variables.tf
        └── services
            └── webserver-cluster
```

이제 스테이징 환경에서 해당 모듈을 사용할 수 있습니다.

모듈을 사용하기 위한 구문은 다음과 같습니다.

```
module "<NAME>" {
	source = "<SOURCE>"

	[CONFIG...]
}
```

여기서 NAME은 테라폼 코드 전체에서 web-service와 같은 모듈을 참조하기 위해 사용할 수 있는 식별자입니다.

SOURCE는 module/services/webserver-cluster 같은 모듈 코드를 찾을 수 있는 경로이며 CONFIG는 그 모듈과 관련된 특정한 하나 이상의 인수로 구성됩니다.

다음은 모듈 사용 예시입니다.
```
provider "aws" {
  region = "us-west-1"
}

module "webserver_cluster" {
  source = "../../../modules/service/webserver-cluster"
}
```

테라폼 모듈을 통해 해당 리소스가 필요한 경우 기존에 작성한 코드를 쉽게 재사용할 수 있습니다.

```
🚨 단, 테라폼 구성에 모듈을 추가하거나 모듈의 source 매개 변수를 수정할 때마다 apply나 plan 명령어를 사용하기 전에 init 명령을 실행해야 한다는 점을 기억해야 합니다.
```

### 모듈 사용시 주의점

현재 작성된 코드들의 이름들은 모두 하드코딩되어 있습니다.

즉, 모듈을 두번이상 사용하게 되면 이름이 충돌하여 문제가 발생하게 됩니다.

이를 해결하기 위해 이름을 외부에서 입력받을 수 있도록 하여 다른 환경에서는 다른 이름으로 동작할 수 있도록 만들어 주어야 합니다.

## 모듈 입력

테라폼 모듈에서 입력 매개 변수를 통해 값을 외부로 부터 입력받을 수 있습니다.

### 입력 변수를 사용하여 입력 받기

다음과 같이 variables.tf 파일을 이용하여 파일의 이름을 지정할 수 있습니다.

```
variable "cluster_name" {
  description = "The name to use for all the cluster resources"
  type = string
}

variable "db_remote_state_bucket" {
  description = "The name of the S3 bucket for the database's remote state"
  type = string
}

variable "db_remote_state_key" {
	description = "The path for the databases's remote state in S3"
	type = string
}
```

변수로 설정한 값을 다음과 같이 적용할 수 있습니다.

```
resource "aws_security_group" "alb" {
  name = "${var.cluster_name}-alb"

  ingress {
	from_port = 80
	to_port = 80
	protocol = "tcp"
	cidr_blocks = ["0.0.0.0/0"]
  }
  ...
}
```

### 모듈에 데이터 전달하기

모듈의 데이터를 변수처리 완료하였으면 모듈을 호출하는 곳에서 다음과 같이 값을 전달하여 상황에 맞게 값을 변경할 수 있습니다.

```
module "webserver_cluster" {
	source = "../../../modules/services/webserver-cluster

	cluster_name = "webservers-prod"
	db_remote_state_bucket = "(YOUR_BUCKET_NAME)"
	db_remote_state_key = "prod/data-stores/mysql/terraform.tfstate"
}
```

## 모듈과 지역변수

입력 변수를 사용하여 모듈의 입력을 정의하는 것도 좋지만 중간에 계산을 수행하거나 코드가 중복되지 않게끔 모듈에서 변수를 정의하는 방법도 필요합니다.

예를 들어 현재 테라폼으로 작성한 로드밸런서는 HTTP의 기본 포트인 80포트로 리스닝합니다.

```
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port = 80
  protocol = "HTTP"

  default_action {
	type = "fixed-response"
	fixed_response {
	  content_type = "text/plain"
	  message_body = "404: page not found"
	  status_code = 404
	}
  }
}
```

로드 밸런서의 보안 그룹에도 마찬가지로 하드 코딩되어 있습니다.
```
resource "aws_security_group" "alb" {
  name = "${var.cluster_name}-alb"

  ingress {
	from_port = 80
	to_port = 80
	protocol = "tcp"
	cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
	from_port = 0
	to_port = 0
	protocol = "-1"
	cidr_blocks = ["0.0.0.0/0"]
  }
}
```

이외에도 모든 IP를 뜻하는 0.0.0.0/0 모든 프로토콜을 의미하는 값 -1 등 여러 값들이 하드코딩되어 관리됩니다.

이러한 하드 코딩된 값들이 많아지면 코드를 읽고 유지보수하기 어려워집니다.

입력변수로 값을 추출하는 방법도 있지만 이 경우 모듈 사용자가 임의로 값을 변경해버릴 수 있습니다.

### locals 블록

이런식으로 특정 값을 상수화 시켜 관리하고 싶을 경우 `locals` 블록을 사용할 수 있습니다.

```
locals {
	http_port = 80
	any_port = 0
	any_protocol = "-1"
	tcp_protocol = "tcp"
	all_ips = ["0.0.0.0/0"]	
}
```

로컬 값을 사용하면 모든 테라폼 표현식에 이름을 할당하고 모듈 전체에서 해당 이름을 사용할 수 있습니다.

이러한 이름은 모듈 내에서만 표시되므로 다른 모듈에는 영향을 미치지 않으며, 모듈 외부에서 이 값을 재정의할 수 없습니다.

로컬 값을 읽을때는 다음과 같이 작성합니다.

```
local.<NAME>
```

이 구문을 사용하여 로드 밸런서 리스너를 업데이트합니다.

```

resource "aws_security_group" "alb" {
  name = "${var.cluster_name}-alb"

  ingress {
	from_port = local.http_port
	to_port = local.http_port
	protocol = local.tcp_protocol
	cidr_blocks = local.all_ips
  }

  egress {
	from_port = local.any_port
	to_port = local.any_port
	protocol = local.any_protocol
	cidr_blocks = local.all_ips
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port = local.http_port
  protocol = "HTTP"

  default_action {
	type = "fixed-response"
	fixed_response {
	  content_type = "text/plain"
	  message_body = "404: page not found"
	  status_code = 404
	}
  }
}
```

## 모듈 출력

특정 환경에서 일정 시간이 되면 오토 스케일링 기능을 추가하는 기능을 만들다고 싶다고 가정해봅시다.

먼저 일정 시간이 되면 오토 스케일링을 진행하는 작업을 다음과 같이 정의하겠습니다.

```
resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
	scheduled_action_name = "scale-out-during-business-hours"
	min_size = 2
	max_size = 10
	desired_capacity = 10
	recurrence = "0 9 * * *"
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
	scheduled_action_name = "scale_in_at_night"
	min_size = 2
	max_size = 10
	desired_capacity = 2
	recurrence = "0 17 * * *"
}
```

위의 코드는 aws_autoscaling_schedule 리소스를 사용하여 오전 시간동안 서버수를 10 늘리고 저녁 시간이 되면 서버 수를 2로 줄입니다.

### 이름을 어떻게 받아올 수 있을까?
aws_autoscaling_schedule은 autoscaling_group_name 이라는 이름 값을 필수로 받아야 합니다.

하지만 오토스케일링 그룹이 모듈 내에 정의되어 있어 액세스하는데 어려움을 겪을 수 있습니다.

사실 테라폼 모듈에서는 간단하게 값을 반환 할 수 있습니다.

바로 `출력 변수`를 이용하면 쉽게 값을 받아올 수 있습니다.

다음은 출력 변수로 오토스케일링 그룹의 이름을 받아오는 예시입니다.
```
output "asg_name" {
	value = aws_autoscaling_group.example.name
	description = "The name of the Auto Scaling Group"
}
```

모듈을 사용하는 곳에서 다음 구문을 통해 모듈 출력 변수에 액세스 할 수 있습니다.

```
module.<MODULE_NAME>.<OUTPUT_NAME>

# 예시
module.frontend.asg_name
```

이제 오토 스케일링 그룹에 출력 변수를 가져오는 구문을 추가하면 일정 시간이 되면 서버를 늘리고 줄일 수 있게 됩니다.

```
resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
	scheduled_action_name = "scale-out-during-business-hours"
	min_size = 2
	max_size = 10
	desired_capacity = 10
	recurrence = "0 9 * * *"

	autoscaling_group_name = module.webserver_cluster.asg_name
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
	scheduled_action_name = "scale_in_at_night"
	min_size = 2
	max_size = 10
	desired_capacity = 2
	recurrence = "0 17 * * *"

	autoscaling_group_name = module.webserver_cluster.asg_name
}
```

## 모듈 주의 사항

### 파일 경로

기본적으로 테라폼은 현재 작업 중인 디렉터리를 기준으로 경로를 해석합니다.

그렇기 때문에 file과 같은 함수를 사용할때는 조심해서 사용해야 합니다.

이러한 문제를 해결하기 위해 다음과 같은 형태로 경로 참조 표현식을 지원하고 있습니다.

```
path.<TYPE>
```

- path.module
  - 표현식이 정의된 모듈의 파일 시스템 경로를 반환합니다.
- path.root
  - 루트 모듈의 파일 시스템 경로를 반환합니다.
- path.cwd
  - 현재 작업중인 디렉터리의 파일 시스템 경로를 반환합니다.
  - 테라폼을 일반적으로 사용할 때 이것은 path.root와 동일하지만 테라폼의 일부 기능은 루트 모듈 디렉터리 이외의 디렉터리에서 작동하므로 경로가 달라집니다.


다음은 사용 예시입니다.

```
data "template_file" "user_data" {
	template = file(${path.module}/user-data.sh)

	vars = {
		...
	}
}
```

### 인라인 블록
일부 테라폼 리소스 구성은 인라인 블록 혹은 별도의 리소스로 정의할 수 있습니다.

모듈을 만들 때는 항상 별도의 리소스를 사용하는 것이 좋습니다.

예를 들어, aws_security_group 리소스를 사용하면 webserver-cluster 모듈에서 볼 수 있듯 인라인 블록을 통해 수신(ingress) 및 송신(egress) 규칙을 정의할 수 있습니다.

```
esource "aws_security_group" "alb" {
  name = "${var.cluster_name}-alb"

  ingress {
	from_port = local.http_port
	to_port = local.http_port
	protocol = local.tcp_protocol
	cidr_blocks = local.all_ips
  }

  egress {
	from_port = local.any_port
	to_port = local.any_port
	protocol = local.any_protocol
	cidr_blocks = local.all_ips
  }
}
```

별도의 aws_security_group_rule 리소스를 사용하면 수신 및 송신 규칙을 분리하여 사용할 수 있습니다.

```
resource "aws_security_group" "alb" {
  name = "${var.cluster_name}-alb"
}

resource "aws_security_group_rule" "allow_http_inbound" {
	type = "ingress"
	security_group_id = aws_security_group.alb.id

	from_port = local.http_port
	to_port = local.http_port
	protocol = local.tcp_protocol
	cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allwo_all_outbound" {
	type = "egress"
	security_group_id = aws_security_group.alb.id

	from_port = local.any_port
	to_port = local.any_port
	protocol = local.any_protocol
	cidr_blocks = local.all_ips
}
```

### 인라인 블록 vs 별도의 리소스로 관리

인라인 블록과 별도의 리소스를 혼합해서 사용하려고 하면 라우팅 규칙이 충돌하면서 서로 덮어쓰는 오류가 발생합니다.

따라서 둘 중 하나만 선택해야하는데 인라인 블록을 사용하면 유연성이 떨어지기 때문에 별도의 리소스를 사용하는 것을 추천합니다.

예를 들어 사용자가 모듈 외부에서 사용자 정의 규칙을 추가할 수 있도록 모듈을 유연하게 만들수도 있습니다.

이를 위해 aws_security_group의 ID를 출력 변수로 보내봅시다.

```
output "alb_security_group_id" {
  value = aws_security_group.alb.id
  description = "The Id of the Security Group attached to the load balancer"
}
```

이제 모듈을 사용하는 쪽에서는 자유롭게 보안 그룹 설정을 추가할 수 있습니다.

```
resource "aws_security_group_rule" "allow_testing_inbound" {
  type = "ingress"
  security_group_id = module.webserver_cluster.alb_security_group_id	

  from_port = 12345
  to_port = 12345
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
```

## 모듈 버전 관리

### 지정된 모듈

스테이징 환경과 프로덕션 환경이 동일한 모듈 폴더를 가리키는 경우 해당 폴더를 변경하면 바로 다음 배포시 두 환경 모두에 영향을 미칩니다.

이러한 종류의 결합은 프로덕션에 영향을 미치지 않고 스테이징 변화를 테스트하기 어렵게 만듭니다.

그래서 서로 다른 환경인 경우 서로 다른 버전의 모듈을 가르키도록 만드는 것이 더 적절합니다.

이를 위해 모듈을 버전이 지정된 모듈로 만드는 것이 좋습니다.

### 지정된 모듈 만들기

지정된 모듈을 만드는 가장 쉬운 방법은 모듈의 코드를 별도의 깃 레포지터리에 넣고 source 매개 변수를 해당 레포지터리의 URL로 설정하는 것입니다.

즉, 테라폼 코드를 최소 2개의 레포지터리에 분산하여 저장하는 것입니다.

- 모듈
  - 이 레포지터리는 재사용 가능한 모듈을 정의합니다.
- 라이브
  - 이 레포지터리는 스테이징, 프로덕션, 관리 등 각 환경에서 실행 중인 인프라를 정의합니다.

이제 테라폼 코드는 다음과 유사한 형태로 변경됩니다.

```
└── code
    ├── live
    │   ├── global
    │   │   └── s3
    │   │       ├── main.tf
    │   │       └── outputs.tf
    │   ├── prod
    │   │   └── services
    │   │       └── web-cluster
    │   │           └── main.tf
    │   └── stage
    │       ├── data-stores
    │       │   └── mysql
    │       │       ├── main.tf
    │       │       ├── outputs.tf
    │       │       └── variables.tf
    │       └── services
    │           └── webserver-cluster
    │               ├── main.tf
    │               └── variables.tf
    └── modules
        └── service
            └── webserver-cluster
                ├── main.tf
                ├── outputs.tf
                ├── user-data.sh
                └── variables.tf

```

이제 modules 폴더에서 깃 레포지터리를 만들고 태그를 추가합니다.

```
cd modules
git init
git add .
git commit -m "Initial commit of modules repo"
git remote add origin "(URL OF REMOTE GIT REPOSITORY)"
git push origin main
git tag -a "v0.0.1" -m "버전 1 배포"
git push --follow-tags
```

이제 특정 테라폼 코드에서 버저닝된 모듈을 사용하려면 다음과 같이 사용할 수 있습니다.

```
provider "aws" {
  region = "us-west-1"
}

module "webserver_cluster" {
  source = "github.com/foo/modules//webserver-cluster?ref=v0.0.1"

	...
}
```

위의 코드 처럼 ref 매개변수를 사용하면 특정 깃 커밋을 지정하거나 브랜치 이름, 특정 깃 태그를 지정할 수 있습니다.

### 모듈의 버전 번호로 깃 태그를 추천

일반적으로 모듈의 버전 번호로는 깃 태그를 사용하는 것을 권합니다.

브랜치는 init 명령어를 실행할 때마다 변하고 항상 최신 커밋을 가져오기 때문에 버전 번호로 사용하기에 안정적이지 않습니다.

특정 커밋 해시 값 역시 사람이 알아보기 어렵기 때문에 적합하지 않습니다.

깃 태그는 깃 커밋만큼 안정적이면서도 친숙하고 읽기 쉽습니다.

### 시맨틱 버전 관리

시맨틱 버전 관리는 특히 태그에 유용한 명명 규칙입니다.

다음과 같은 형식으로 이루어집니다.

```
MAJOR.MINOR.PATH
```
- MAJOR : 호환되지 않는 API 변경 시 증가
- MINOR : 이전 버전과 호환되는 방식으로 기능을 추가할 때 증가
- PATH : 이전 버전과 호환되는 버그 수정시 증가

시맨틱 버전관리를 사용하면 모듈의 사용자에게 어떤 종류의 변경 사항이 있는지와 업그레이드가 어떤 영향을 주는지 전달할 수 있습니다.

## 정리

코드형 인프라에서 모듈을 사용하면 다음과 같은 장점이 존재합니다.
1. 다양한 소프트웨어 엔지니어링 모범 사례를 인프라에 적용할 수 있습니다.
2. 코드 리뷰 및 자동화된 테스트를 통해 모듈의 변경사항을 확인할 수 있습니다.
3. 각 모듈에 버전을 지정하여 배포할 수 있습니다.
4. 다른 환경에서 다른 버전의 모듈을 안전하게 사용해보고 문제가 발생하면 이전 버전으로 롤백할 수 있습니다.
5. 개발자들이 검증과 테스트를 거쳐 문사화된 인프라 전체를 재사용할 수 있기 때문에 인프라를 빠르고 안정적으로 구축할 수 있습니다.