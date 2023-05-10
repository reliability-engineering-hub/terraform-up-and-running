# 테라폼 코드 테스트

## 수동 테스트
### 테라폼으로 테스트가 어려운 이유

테라폼 코드는 로컬 호스트로 실행할 방법이 없기때문에 테스트하기 어렵습니다.

이는  테라폼 뿐만 아니라 대부분의 코드형 인프라 도구에 적용됩니다.

### 테라폼으로 수동 테스트 하기

테라폼으로 수동 테스트를 실행할 수 있는 유일한 방법은 AWS 같은 실제 환경에 배포하는 것입니다.

다시 말해 terraform apply 및 terraform destroy를 수동으로 실행하는 것이 테라폼으로 수동 테스트를 수행하는 방법입니다.

그리고 테스트시에는 curl 같은 명령을 사용하여 인프라를 테스트하게 됩니다.

### 테스트하기 좋은 테라폼 코드

테라폼으로 작업할 때 모든 개발자에게는 테스트를 위한 좋은 예제 코드가 필요합니다.

또한 테스트를 실행하기 위해 로컬 호스트와 동등하게 사용할 수 있는 AWS 계정 같은 실제 배포 환경이 필요합니다.

수동 테스트 과정에서 많은 인프라를 구축 및 해체하고 많은 실수를 겪을 가능성이 있으므로 이 환경은 스테이징, 프로덕션과 같은 다른 안정된 환경과 완전히 격리되어야 합니다.

따라서 모든 팀이 격리된 샌드박스 환경을 설정할 것을 권합니다.

이 경우 개발자는 다른 샌드박스 환경에 영향을 줄 염려 없이 원하는 인프라를 구축하고 해체할 수 있습니다.

예를 들어, 두 명의 개발자가 동일한 이름으로 로드 밸런서 생성을 시도하는 경우와 같이 여러 개발자 간 충돌 가능성을 줄이려면 각 개발자가 완전히 고립된 샌드박스 환경을 설정하는 것이 훌륭한 방법입니다.

예를 들어, AWS와 함께 테라폼을 사용하는 경우 각 개발자가 원하는 것을 테스트하는 데 사용할 수 있는 자체 AWS 계정을 갖는 것이 중요합니다.

### 테스트 후 정리

많은 샌드박스 환경을 갖누는 것은 좋지만 모든 환경을 복잡하게 만들고 큰 비용을 발생시킬 수 있습니다.

비용을 줄이기 위해서는 샌드박스 환경을 정기적으로 정리할 필요가 있습니다.

예를 들어, 테스트를 완료하면 terraform destroy를 실행하여 개발자가 배포한 모든 것을 정리하는 문화를 만들어야 합니다.

사용자의 배포 환경에 따라 사용하지 않거나 오래된 리소스를 자동으로 정리하기 위해 크론 작업과 같이 정기적으로 실행할 수 있는 도구를 찾아야할 수 도 있습니다.

- cloud-nuke
    - 클라우드 환경의 모든 리소스를 삭제할 수 있는 오픈 소스 도구입니다.
    - Amazon EC2 인스턴스, ASG, ELB 등 AWS의 여러 리소스를 지원하며 구글 클라우드, 애저 같은 다른 리소스 및 기타 클라우드도 지원 예정입니다.
    - 주로 특정 기간보다 오래된 모든 리소스를 삭제하는데 사용됩니다.
- JanitorMonkey
    - 구성하는 일정에 따라 AWS 리소스를 정리하는 오픈 소스 도구입니다.
    - 리소스 정리 여부 및 삭제하기 전에 며칠 전에 리소스 소유자에게 알림을 보내는 기능을 결정하는 구성 규칙도 지원합니다.
- aws-nuke
    - AWS 계정에서 모든 것을 삭제하는데 사용하는 오픈소스 도구입니다.
    - YAML 파일을 사용하며 삭제할 계정 및 리소스를 지정합니다.
## 자동화된 테스트와 단위 테스트
### 자동화된 테스트란?

자동화된 테스트는 실제 코드가 정상적으로 작동하는지 검증하는 테스트 코드를 작성하는 것입니다.

모든 커밋 후에 이러한 테스트를 실행하도록 CI 서버를 만들어 실패시 코드를 롤백시켜 항상 코드를 작동하는 상태로 유지할 수 있습니다.

### 자동화된 테스트 유형

자동화된 테스트에는 다음과 같은 3가지 유형이 있습니다.

- 단위 테스트
    - 단위테스트는 하나의 작은 코드 단위의 기능을 검증합니다.
- 통합 테스트
    - 여러 단위가 올바르게 작동하는지 확인합니다.
- 종단 간 테스트
    - 종단간 테스트는 앱, 데이터 저장소, 로드 밸런서와 같은 전체 아키텍처를 실행하고 시스템이 전체적으로 작동하는지 확인하는 과정을 포함합니다.

### 각 테스트 간의 목적

각 유형의 테스트는 서로 다른 목적으로 사용되며, 다양한 유형의 버그를 포착할 수 있기 때문에 세가지 유형을 혼합하여 사용하는 경우가 많습니다.

단위 테스트의 목적은 변경 사항에 대한 빠른 피드백을 얻고 다양한 순열을 검증하여 코드의 기본 빌딩 블록이 예상대로 작동하는지 확신할 수 있도록 빠른 테스트를 수행하는 것입니다.

그러나 개별 단위가 각각 올바르게 작동한다고 해서 결합 시 올바르게 작동한다는 의미는 아닙니다.

따라서 기본 빌딩 블록이 올바르게 결합되도록 통합 테스트를 수행해야 합니다.

또한 시스템의 여러 부분이 올바르게 작동한다고 해서 실제 환경에 배포할 때 제대로 작동한다는 의미는 아니므로 프로덕션과 유사한 조건에서 코드가 예상대로 작동하는지 확인하려면 종단 간 테스트를 수행해야 합니다.

### 단위 테스트하기 어려운 코드

단위 테스트하기 어려운 코드라면 코드 스멜일 가능성이 높으며 코드를 리팩터링해야 합니다.

이를 위해 코드를 하나의 역할만 하도록 간단하게 작성하는 것이 좋습니다.

### 테라폼으로 단위 테스트 진행하기

먼저 테라폼 코드에서 단위가 무엇인지 정의하는 것 부터 시작해봅시다.

테라폼에서 단일 함수 또는 클래스와 가장 가까운 것은 단일 일반 모듈입니다.

기존의 프로그래밍 언어에서는 종속성 없이 코드를 작성하여 단위 테스트에 용이하도록 코드를 작성했었습니다.

하지만 테라폼은 특정 클라우드 서비스에 종속성을 가지고 통신하고 있기 때문에 이러한 방식을 적용하기 어렵습니다.

즉, 테라폼 코드는 순수한 단위테스트를 수행할 수 없습니다.

그래서 테라폼은 단위 테스트를 할 수 없고 클라우드 서비스를 사용하여 실제로 동작하는지 확인하는 통합테스트를 진행하게 됩니다.

하지만 각각의 단일 일반 모듈을 우선적으로 테스트하기 때문에 이를 단위 테스트라고 부르는 것을 선호합니다.

### 테라폼의 단위 테스트 기본 전략

1. 일반 독립형 모듈을 작성합니다.
2. 해당 모듈에 대한 배포하기 쉬운 예제를 작성합니다.
3. terraform apply를 실행하여 예제를 실제 환경에 배포합니다.
4. 방금 배포한 모듈이 예상대로 작동하는지 검증합니다. 이 단계는 테스트 중인 인프라 유형에 따라 다릅니다. 예를 들어 ALB의 경우 HTTP 요청을 보내고 예상 응답이 다시 수신되는지 확인하여 ALB를 검증합니다.
5. 테스트가 끝나면 terraform destroy를 실행하여 정리합니다.

즉, 수동 테스트를 수행할때와 동일한 단계를 수행하지만 해당 단계를 코드로 캡처합니다.

실제로 이는 테라폼 코드에 대한 자동화된 테스트를 생성하기 위한 좋은 모델입니다.

### 테라테스트를 통한 테스트 코드 작성

테스트 코드는 어떤 프로그래밍 언어로도 작성할 수 있습니다.

이번에는 테라테스트라는 라이브러리를 활용하여 Go언어로 작성해봅시다.

이 라이브러리는 AWS, 구글 클라우드, 쿠버네티스와 같은 다양한 환경에 걸쳐 테라폼, 패커, 도커, 헬름과 같은 코드형 인프라 도구 테스트를 지원합니다.

테라테스트에는 인프라 코드를 훨씬 쉽게 테스트할 수 있는 수백 개의 도구가 내장되어 있습니다.

테스트 전략을 지원하기 위해 다음과 같은 과정에서 적용할 수 있는 기능들을 제공합니다.

- terraform apply
- 동작에 대한 검증
- terraform destroy

```
💡 테라테스트를 사용하기 위해서는 Go 언어가 필요하므로, 미리 Go를 설치해야 합니다.
```

Terratest를 작성하기 전에 다음과 같이 Go 코드를 작성합시다.

```go
package test

import (
	"fmt"
	"testing"
)

func TestGoIsWorking(t *testing.T) {
	fmt.Println()
	fmt.Println("If you see this text, it's working!")
	fmt.Println()
}
```

`go test -v` 명령 실행 후 다음과 같은 메시지가 출력되면 정상적으로 동작하는 것입니다.

```go
=== RUN   TestGoIsWorking

If you see this text, it's working!

--- PASS: TestGoIsWorking (0.00s)
PASS
```

### 테라테스트 작성하기

이제 테스트 폴더에 alb를 테스트하는 코드를 작성해봅시다.

먼저, terraform.Options를 사용하여 테스트를 테라폼 코드가 있는 위치로 지정해봅시다.

```go
package test

import (
	"github.com/gruntwork-io/terratest/modules/terraform"
	"testing"
)

func TestAlbExample(t *testing.T) {
	opts := &terraform.Options{
		TerraformDir: "../module/alb",
	}
}
```

다음으로 테라폼 코드를 실행하기 위해 terraform init 및 terraform apply를 실행하여 코드를 배포해봅시다.

테라테스트는 이를 위해 Init 함수와 Apply 함수를 제공합니다.

```go
func TestAlbExample(t *testing.T) {
	opts := &terraform.Options{
		TerraformDir: "../module/alb",
	}
	terraform.Init(t, opts)
	terraform.Apply(t, opts)
}
```

다음과 같이 InitAndApply 메서드로 한번에 수행할 수도 있습니다.

```go
func TestAlbExample(t *testing.T) {
	opts := &terraform.Options{
		TerraformDir: "../module/alb",
	}
	terraform.InitAndApply(t, opts)
}
```

### ALB 도메인 이름 얻기

위의 코드까지만 작성해도 terraform init 및 terraform apply를 실행하고 테라폼 코드 문제등으로 인해 해당 명령이 성공적으로 완료되지 않으면 테스트에 실패하기 때문에 이미 유용한 단위 테스트입니다.

그러나 배포된 로드 밸런서에 HTTP 요청을 하고 예상한 데이터를 반환하는지 확인하면 한 걸음 더 나아갈 수 있습니다.

이를 위해 이미 배포된 로드밸런서의 도메인 이름을 얻는 방법이 필요합니다.

마침 ALB 모듈에서 출력한 변수를 사용할 수 있습니다.

```go
output "alb_dns_name" {
  value       = aws_lb.example.dns_name
  description = "The domain name of the load balancer"
}
```

테라테스트에는 테라폼 코드의 출력을 읽을 수 있는 헬퍼가 내장되어 있습니다.

```go
func TestAlbExample(t *testing.T) {
	// 모듈 위치 지정
	opts := &terraform.Options{
		TerraformDir: "../module/alb",
	}

	// 테라폼 init 및 apply
	terraform.InitAndApply(t, opts)

	// ALB의 URL 정보 가져오기
	albDnsName := terraform.OutputRequired(t, opts, "alb_dns_name")
	url := fmt.Sprintf("http://%s", albDnsName)
}
```

위의 코드는 OutputRequired 함수를 이용하여 주어진 이름의 출력을 반환하고 해당 출력이 없거나 비어 있으면 테스트에 실패합니다.

그리고 Go에 내장된 fmt.Sprintf 함수를 사용하여 이 출력에서 URL을 작성합니다.

### URL에 HTTP 요청하기

이제 URL에 HTTP 요청을 하는 코드를 작성해봅시다.

```go
func TestAlbExample(t *testing.T) {
	// 모듈 위치 지정
	opts := &terraform.Options{
		TerraformDir: "../module/alb",
	}

	// 테라폼 init 및 apply
	terraform.InitAndApply(t, opts)

	// ALB의 URL 정보 가져오기
	albDnsName := terraform.OutputRequired(t, opts, "alb_dns_name")
	url := fmt.Sprintf("http://%s", albDnsName)

	// ALB의 기본 동작이 작동하고 404를 반환하는지 테스트

	expectedStatus := 404
	expectedBody := "404: page not found"

	http_helper.HttpGetWithValidation(t, url, &tls.Config{}, expectedStatus, expectedBody)
}
```

http_helper.HttpGetWithValidation 메서드는 전달한 URL로 HTTP GET 요청을 작성하고 응답에 지정한 상태 코드 및 본문이 없는 경우 테스트에 실패합니다.

### 현재 작성한 테스트 코드의 문제점

현재 작성한 코드에는 문제가 존재합니다.

terraform apply 명령이 실행된 후 로드 밸런서의 DNS 이름이 작동하는 시점에 짧은 대기 시간이 존재합니다.

그렇기 때문에 http_helper.HttpGetWithValidation를 즉시 실행하면 작동하지 않을 수도 있습니다.

이를 해결하기 위해서는 실패시 재시도를 요청하는 방법이 일반적입니다.

다음과 같은 코드를 변경합시다.

```go
func TestAlbExample(t *testing.T) {
	// 모듈 위치 지정
	opts := &terraform.Options{
		TerraformDir: "../module/alb",
	}

	// 테라폼 init 및 apply
	terraform.InitAndApply(t, opts)

	// ALB의 URL 정보 가져오기
	albDnsName := terraform.OutputRequired(t, opts, "alb_dns_name")
	url := fmt.Sprintf("http://%s", albDnsName)

	// ALB의 기본 동작이 작동하고 404를 반환하는지 테스트

	expectedStatus := 404
	expectedBody := "404: page not found"

	maxRetries := 10
	timeBetweenRetries := 10 * time.Second

	http_helper.HttpGetWithRetry(
		t,
		url,
		&tls.Config{},
		expectedStatus,
		expectedBody,
		maxRetries,
		timeBetweenRetries,
	)
}
```

http_helper.HttpGetWithRetry 메서드는 http_helper.HttpGetWithValidation과 거의 동일하지만 예상 상태 코드 또는 본문을 다시 가져오지 않으며 지정된 재시도 간격으로 지정된 최대 횟수까지 재시도 합니다.

재시도 중에 응답이 성공하면 테스트는 통과하게 됩니다.

### 테스트 완료 후 리소스 정리

자동화된 테스트를 수행할 때 마지막으로 해야 할 일은 테스트가 끝날 때 terraform destroy를 실행하여 정리하는 것입니다.

테라테스트에는 Destroy 함수가 존재하기 때문에 리소스를 제거하려면 해당 함수를 호출하면 됩니다.

하지만 정상적으로 테스트가 종료되지 않는 경우 terraform.Destroy에 도달하기 전에 테스트 코드가 종료될 수 있습니다.

이런 상황에서 Go는 defer 문을 이용하여 특정 코드가 실행되는 것을 보장할 수 있습니다.

코드에 Destroy 함수를 호출하는 defer 문을 추가해봅시다.

```go
func TestAlbExample(t *testing.T) {
	// 모듈 위치 지정
	opts := &terraform.Options{
		TerraformDir: "../module/alb",
	}

	// 테스트 종료시 모든 리소스 삭제
	defer terraform.Destroy(t, opts)
	
	// 테라폼 init 및 apply
	terraform.InitAndApply(t, opts)

	// ALB의 URL 정보 가져오기
	albDnsName := terraform.OutputRequired(t, opts, "alb_dns_name")
	url := fmt.Sprintf("http://%s", albDnsName)

	// ALB의 기본 동작이 작동하고 404를 반환하는지 테스트

	expectedStatus := 404
	expectedBody := "404: page not found"

	maxRetries := 10
	timeBetweenRetries := 10 * time.Second

	http_helper.HttpGetWithRetry(
		t,
		url,
		&tls.Config{},
		expectedStatus,
		expectedBody,
		maxRetries,
		timeBetweenRetries,
	)
}
```

### 테스트 작성 완료 후 실행

이제 단위 테스트를 실행할 준비가 되었습니다.

작성한 테스트는 인프라를 AWS에 배포하기 때문에 테스트를 실행하기 전에 평소와 같이 AWS 계정에 대한 인증을 받아야 합니다.

그리고 자동화된 테스트의 경우 기존의 리소스가 있는 곳이 아닌 격리된 환경에서 테스트를 수행하는 것이 안전하기 때문에 별도의 영역에서 진행하는 것이 좋습니다.

AWS 계정 인증 후 다음과 같이 테스트 코드를 실행해봅시다.

```go
go test -v -timeout 30m
```

```
💡 위의 코드에서 timeout 시간을 지정하는 이유는 go는 기본적으로 테스트의 10분의 시간 제한을 적용하여 10분 이상이 걸릴 경우 테스트가 실패하게 됩니다.

테라폼 테스트 코드의 경우 시간이 오래걸리므로 이러한 테스트가 오래걸려 실패하는 상황을 막기 위해 timeout을 지정하는 것입니다.
```

테스트 로그를 확인해보면 다음과 같이 실행되는 것을 볼 수 있습니다.

1. terraform init 실행
2. terraform apply 실행
3. terraform output을 사용하여 출력 변수 읽기
4. ALB에 반복적으로 HTTP 요청
5. terraform destroy 실행

테스트 시간이 좀 걸리긴 하지만 자동으로 테스트가 실행되는지 확인할 수 있다는 장점이 있습니다.

이는 AWS의 인프라에서 가장 빠르게 얻을 수 있는 피드백이며, 코드가 예상대로 동작한다는 확신을 줄 수 있습니다.

예를 들어, 기본 작업의 상태 코드를 401로 변경하는 것 같이 코드 작성에서 실수를 한 경우 해당 정보를 빠르게 알 수 있습니다.

### 종속성 주입

단위 테스트를 작성할때 외부 종속성을 포함하는 경우 다음과 같은 문제가 발생할 수 있습니다.

- 해당 종속성과 통신하는데 장애가 있으면 코드에 아무런 문제가 없더라도 테스트가 실패하게 됩니다.
- 해당 종속성에 변경이 일어날 경우 기존에 작성한 테스트 코드가 실패하며, 이 때문에 테스트를 지속적으로 업데이트 해야 합니다.
- 종속성이 느릴 경우 작성한 테스트 속도 역시 느려집니다.

실제 종속성을 사용하여 작업하는 것이 통합이나 종단간 테스트에는 적합할 수 있지만 단위테스트의 경우에는 외부 종속성을 가능한 최소화해서 작성해야 합니다.

이를 수행하는 일반적인 전략은 종속성 주입으로써 코드 내에서 하드 코딩하지 않고 코드 외부에서 외부 종속성을 주입하는 방식입니다.

종속성 주입을 사용하면 빠르고 안정적인 단위 테스트를 작성하고 다양한 케이스들을 쉽게 확인할 수 있습니다.

### 테라폼 모듈에서의 종속성 주입

이번에는 기존에 만들었던 hello-world-app 모듈을 예시로 들어 보겠습니다.

테라폼 코드는 다음과 같습니다.

```go
provider "aws" {
  region = "us-west-1"
}

module "hello_world_app" {
  source = "../../module/app"

  server_text = "Hello, World"
  environment = "example"

  db_remote_state_bucket = "yckim-terratest-example-bucket"
  db_remote_state_key = "examples/terraform.tfstate"

  instance_type = "t2.micro"
  min_size = 2
  max_size = 2
  enable_autoscaling = false
}
```

코드를 보면 종속성 문제가 발생하고 있는 것을 알 수 있습니다.

app을 실행하기 위해서 mysql 모듈과 S3 버킷의 세부 정보 필요한 것을 볼 수 있습니다.

여기서 목표는 hello-world-app 모듈에 대한 단위 테스트를 작성하는 것입니다.

테라폼에서 외부 종속성이 0인 순수한 단위 테스트를 작성할 수는 없지만 가능한 외부 종속성은 최소화하는 것이 좋습니다.

### 모듈의 종속성을 명확하게 하기

종속성을 최소화하기 위한 첫 번째 단계는 모듈의 종속성을 명확하게 하는 것입니다.

외부 종속성을 나타내는 모든 데이터 소스와 리소스를 별도의 [dependencies.tf](http://dependencies.tf) 파일로 이동해 분리합시다.

```go
data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = var.db_remote_state_bucket
    key = var.db_remote_state_key
    region = "us-west-1"
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
} 
```

외부 종속성을 별도의 파일로 표현함으로써 코드 사용자는 이 코드가 외부 세계에서 어디에 의존하는지 한눈에 쉽게 알 수 있습니다.

hello-world-app 모듈의 경우 데이터베이스, VPC 및 서브넷에 따라 달라지는 것을 빠르게 확인할 수 있습니다.

이제 테스트시 해당 부분을 교체할 수 있도록 입력 변수를 사용하여 주입 받아봅시다.

다음과 같이 종속성에 대한 입력 변수를 추가합시다.

```go
variable "vpc_id" {
  description = "The ID of the VPC to deploy into"
  type = string
  default = null
}

variable "subnet_ids" {
  description = "The IDs of the subnets to deploy into"
  type = list(string)
  default = null
}

variable "mysql_config" {
  description = "The config for the MySQL DB"
  type = object({
    address = string
    port = number
  })
  default = null
}
```

이제 VPC ID와 서브넷 ID, MySQL 구성에 대한 입력변수가 생겼습니다.

각 변수는 default를 지정하므로 사용자가 default 값을 얻기 위해 사용자 정의하거나 생략할 수 있는 선택적 변수입니다.

### default에 null 값을 설정한 이유

각 변수의 default는 `null` 값을 사용하고 있습니다.

vpc_id나 subnet_id의 빈 리스트처럼 비어있는 값을 전달할 경우 기본 값으로 빈 값을 전달했는지 사용자가 의도적으로 빈 값을 전달했는지 구분하기 어렵습니다.

하지만 null 값을 설정하면 의도적으로 전달한 것을 명확히 나타내므로 이러한 경우에 유용합니다.

mysql_config 변수는 object 유형 생성자를 사용하여 address 및 port 키가 있는 중첩 유형을 만듭니다.

이 유형은 의도적으로 mysql 모듈의 출력 유형과 일치하도록 만들었습니다.

```go
output "address" {
	value = aws_db_instance.example.address
	description = "Connect to the database at this endpoint"
}

output "port" {
	value = aws_db_instance.example.port
	description = "The port the database is listening on"
}
```

### 테라폼 코드에 종속성 주입하기

종속성 주입을 위해 리팩터링을 완료한 후 다음과 같이 코드를 작성할 수 있습니다.

```go
provider "aws" {
  region = "us-west-1"
}

module "hello_world_app" {
  source = "../../module/app"

  server_text = "Hello, World"
  environment = "example"

  mysql_config = module.mysql

  instance_type = "t2.micro"
  min_size = 2
  max_size = 2
  enable_autoscaling = false
}

module "mysql" {
  source = "../../module/mysql"

  db_name = var.db_name
  db_username = var.db_username
  db_password = var.db_password
}
```

mysql_config의 type은 mysql 모듈 출력 유형과 일치하기 때문에 한 줄로 모두 전달할 수 있습니다.

그리고 유형이 변경되어 더 이상 일치하지 않으면 테라폼에서 오류를 즉시 알려서 업데이트할 수 있도록 합니다.

이를 통해 안전하게 합수를 합성할 수 있게 됩니다.

mysql을 입력으로 전달할 수 있도록 변경했기 때문에 db_remote_state_bucket 및 db_remote_state_key를 선택 변수로 설정해야 합니다.

```go
variable "db_remote_state_bucket" {
  description = "The name of the S3 bucket used for the database's remote state storage"
  type        = string
  default = null
}

variable "db_remote_state_key" {
  description = "The name of the key in the S3 bucket used for the database's remote state storage"
  type        = string
  default = null
}
```

그런 다음 해당 입력 변수가 null로 설정되어 있는지 여부에 따라 선택적으로 생성하도록 count 매개변수를 작성하여 코드를 작성합니다.

```go
data "terraform_remote_state" "db" {
  count = var.mysql_config == null ? 1 : 0
  backend = "s3"

  config = {
    bucket = var.db_remote_state_bucket
    key = var.db_remote_state_key
    region = "us-west-1"
  }
}

data "aws_vpc" "default" {
  count = var.vpc_id == null ? 1 : 0
  default = true
}

data "aws_subnet_ids" "default" {
  count = var.subnet_ids == null ? 1 : 0
  vpc_id = data.aws_vpc.default.id
}
```

이제 입력 변수나 데이터 소스를 조건부로 사용하려면 이러한 데이터 소스에 대한 참조를 업데이트해야 합니다.

이를 로컬 값으로 묶겠습니다.

```go
locals {
  mysql_config = (
  var.mysql_config == null
  ? data.terraform_remote_state.db[0].outputs
  : var.mysql_config
  )

  vpc_id = (
  var.vpc_id == null
  ? data.aws_vpc.default[0].id
  : var.vpc_id
  )

  subnet_ids = (
  var.subnet_ids == null
  ? data.aws_subnet_ids.default[0].ids
  : var.subnet_ids
  )
}
```

```
💡 데이터 소스가 count 매개변수를 사용해 배열이 되었으므로 참조할 때마다 [0]과 같은 배열 조회 구문을 사용해야 합니다
```

코드 중에 데이터 소스 중 하나에 대한 참조를 찾는다면 해당 부분을 로컬 값에 대한 참조로 변경합니다.

```go
data "aws_subnet_ids" "default" {
  count = var.subnet_ids == null ? 1 : 0
  vpc_id = local.vpc_id
}
```

그런 다음 asg 및 alb 모듈의 subnet_ids 매개 변수를 설정하여 local.subnet_ids를 사용합니다.

```go
module "asg" {
  source = "../asg"

  cluster_name  = "hello-world-${var.environment}"
  ami           = var.ami
  user_data     = data.template_file.user_data.rendered
  instance_type = var.instance_type

  min_size           = var.min_size
  max_size           = var.max_size
  enable_autoscaling = var.enable_autoscaling

  subnet_ids        = local.subnet_ids
  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  custom_tags = var.custom_tags
}
```

```go
module "alb" {
  source = "../alb"

  alb_name   = "hello-world-${var.environment}"
  subnet_ids = local.subnet_ids
}
```

다음으로 local.mysql_config를 사용하도록 user_data에서 db_address 및 db_port 변수를 업데이트합니다.

```go
data "template_file" "user_data" {
  template = file("${path.module}/user-data.sh")

  vars = {
    server_port = var.server_port
    db_address  = local.mysql_config.address
    db_port     = local.mysql_config.port
    server_text = var.server_text
  }
}
```

마지막으로 aws_lb_target_group의 vpc_id 매개 변수를 업데이트 하여 local.vpc_id를 사용하도록 합니다.

```go
resource "aws_lb_target_group" "asg" {
  name     = "hello-world-${var.environment}"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = local.vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}
```

이러한 업데이트를 통해 VPC ID, 서브넷 ID 및 혹은 MySQL 구성 매개 변수를 hello-world-app 모듈에 주입하거나 해당 매개 변수 중 하나를 생략할 수 있으며 모듈은 적절한 데이터 소스를 사용하여 자체적으로 값을 가져올 수 있습니다.

이제 모듈을 사용하는 테라폼 파일에서 다음과 같이 mock 처리한 구성을 주입해줍니다.

```go
variable "mysql_config" {
  description = "The Config for the MySQL DB"

  type = object({
    address = string
    port = number
  })
  default = {
    address = "mock-mysql-address"
    port = 12345
  }
}
```

그리고 새로 만든 입력변수를 hello-world-app 모듈에 전달합니다.

```go
module "hello_world_app" {
  source = "../../module/app"

  server_text = "Hello, World"
  environment = "example"

  mysql_config = var.mysql_config

  instance_type = "t2.micro"
  min_size = 2
  max_size = 2
  enable_autoscaling = false
}
```

이제 다음과 같이 단위테스트를 작성해봅시다.

```go
func TestHelloWorldAppExample(t *testing.T) {
	opts := &terraform.Options{
		TerraformDir: "../../dev/app",
	}

	defer terraform.Destroy(t, opts)

	terraform.InitAndApply(t, opts)

	albDnsName := terraform.OutputRequired(t, opts, "alb_dns_name")
	url := fmt.Sprintf("http://%s", albDnsName)

	maxRetries := 10
	timeBetweenRetries := 10 * time.Second

	http_helper.HttpGetWithRetryWithCustomValidation(
		t,
		url,
		&tls.Config{},
		maxRetries,
		timeBetweenRetries,
		func(status int, body string) bool {
			return status == 200 && strings.Contains(body, "Hello World")
		},
	)
}
```

이 코드는 alb 예제의 단위 테스트와 거의 동일하지만 두 가지 차이점이 있습니다.

- TerraformDir 설정이 alb 예제 대신 hello-world-app 예제를 가리킵니다.
    
    파일 시스템에 필요한 경로를 반드시 업데이트해야 합니다.
    
- http_helper.HttpGetWithRetry를 사용하여 404 응답을 확인하는 대신 http_helper.HttpGetWithRetryWithCustomValidation 메서드를 사용하여 200 응답과 hello, world 라는 텍스트가 포함된 본문을 확인합니다.
    
    hello-world-app 모듈의 사용자 데이터 스크립트가 이 서버 텍스트를 포함하는 HTML로 200 OK 응답을 반환할걸 기대하기 때문입니다.
    

### DB 접속 정보 추가

이제 테스트 코드에 webserver에서 사용하는 mysql_config 변수를 추가해줍시다.

```go
opts := &terraform.Options{
		TerraformDir: "../../dev/app",

		Vars: map[string]interface{}{
			"mysql_config": map[string]interface{}{
				"address": "mock-value-for-test",
				"port":    3306,
			},
		},
	}
```

terraform.Options의 Vars 매개 변수를 사용하면 테라폼 코드에 변수를 설정할 수 있습니다.

이 코드는 mysql_config 변수에 대한 일부 목 데이터를 전달합니다.

또는 이 값을 원하는 값으로 설정할 수 있습니다.

예를 들어 테스트할 때 작은 인-메모리 데이터베이스를 시작하고 address를 해당 데이터베이스의 IP로 설정할 수 있습니다.

이 테스트만 실행할 -run 인수를 지정한 go test 명령어를 사용하여 이 새로운 테스트를 진행합니다.

그렇지 않으면 Go의 기본동작은 이전에 만든 ALB 예제 테스트를 포함하여 현재 폴더의 모든 테스트를 실행합니다.

### 병렬로 테스트 실행

인프라 코드로 테스트를 실행하는데 걸리는 시간은 4 ~ 5분 정도 걸립니다.

만약 테스트가 수십 개가 존재한다면 각 테스트가 순차적으로 실행되는 경우 전체 테스트 묶음을 실행하는데 몇 시간이 걸릴 수 있습니다.

피드백 루프를 줄이려면 가능한 많은 테스트를 병렬로 실행해야 합니다.

다음 테스트 코드를 병렬로 실행하기 위해 t.Parallel()을 추가합시다.

```go
func test(t *testing.T) {
	t.Parallel()
	...
}
```

go test를 실행하면 t.Parallel()을 지정한 테스트들이 병렬로 실행됩니다.

하지만 ASG, 보안 그룹 및 ALB와 같이 해당 테스트에서 생성된 일부 리소스들이 동일한 이름을 사용하기 때문에 테스트가 실패하게 됩니다.

테스트에서 t.Parallel()을 사용하지 않더라도 팀의 여러 사람들이 동일한 테스트를 실행하거나 CI 환경에서 테스트를 실행하는 경우 이러한 종류의 이름 충돌이 불가피합니다.

이런 상황을 막기위해 모든 리소스의 네임 스페이스를 지정해야 합니다.

즉, 모든 리소스의 이름을 선택적으로 구성할 수 있도록 모듈 및 예제를 디자인해야합니다.

예를들어 특정 리소스의 경우 다음과 같이 랜덤 값을 사용하도록 설정합니다.

```go
opts := &terraform.Options{
		TerraformDir: "../../../module/alb",

		Vars: map[string]interface{}{
				"alb_name": fmt.Sprintf("test-%s", random.UniqueId()),
		},
	}
```

이 코드는 alb_name 변수를 test-<RANDOM_ID>로 설정하여 충돌을 최대한 발생하지 않도록 할 수 있습니다.

이런식으로 랜덤 값을 주어 리소스들 간의 이름 충돌을 회피할 수 있습니다.

이제 테스트를 동시에 실행할 수 있기 때문에 모든 테스트가 동작하는데 걸리는 시간이 가장 오래걸리는 테스트 시간 만큼만 소요됩니다.

```
💡 Go가 병렬로 실행할 테스트 수는 컴퓨터에 있는 CPU 수와 같습니다.
따라서, CPU가 하나뿐인 경우 기본적으로 테스트는 병렬이 아닌 순차적으로 실행됩니다.

이런 상황에서 GOMAXPROCS 환경 변수를 설정하거나 -parallel 인수를 전달하여 해결할 수 있습니다.
```


### 동일한 폴더에 병렬로 테스트 실행

동일한 테라폼 폴더에서 다수의 자동화된 테스트를 병렬로 실행하려고 할때 또 다른 병렬성을 고려해야 합니다.

예를 들어, 같은 디렉터리에서 테스트를 실행하는 경우 동시에 terraform init을 실행하고 테라폼 상태 파일을 덮어쓰려고 하기때문에 충돌이 발생할 수 있습니다.

이를 해결하는 가장 쉬운 방법은 각 테스트가 해당 폴더를 고유한 임시 폴더에 복사하고 임시 폴더에서 테라폼을 실행해 충돌을 방지할 수 있습니다.

테라테스트에는 이를 위한 함수가 내장되어 있습니다.(test_structure.CopyTerraformFolderToTemp)
## 통합 테스트
### 테라폼 코드로 통합 테스트 작성하기

테라폼의 단위를 단일 모듈이라고 가정했을때 여러 단위가 함께 작동하는 방식을 검증하는 통합 테스트는 여러 모듈을 배포하고 제대로 작동하는지 확인해야 합니다.

### 테스트 단계

통합 테스트를 위한 코드를 살펴보면 5가지 단계로 구성되어 있음을 알 수 있습니다.

1. mysql 모듈에서 terraform apply를 실행
2. hello-world-app 모듈에서 terraform apply를 실행
3. 유효성 검증을 실행하여 모든 것이 작동하는지 확인
4. hello-world-app 모듈에서 terraform destroy를 실행
5. mysql 모듈에서 terraform destroy를 실행

CI 환경에서는 이러한 테스트를 처음부터 끝까지 실행해야 합니다.

하지만, 로컬에서 코드를 수정할때는 이러한 단계를 모두 실행할 필요가 없습니다.

왜냐하면, 변경이 mysql 모듈에 아무런 영향을 미치지 않더라도 실행할 경우 mysql 모듈을 배포하고 취소하는 비용을 계속 지불해야 하기 때문입니다.

그렇기 때문에 이상적인 워크플로우는 다음과 같습니다.

1. mysql 모듈에서 terraform apply를 실행
2. hello-world-app 모듈에서 terraform apply를 실행
3. 개발 과정 반복
    1. hello-world-app 모듈을 변경
    2. hello-world-app 모듈에서 terraform apply를 다시 실행하여 업데이트를 배포
    3. 유효성 검증을 실행하여 모든 것이 작동하는지 확인
    4. 모든 것이 작동하면 다음 단계로 넘어감, 그렇지 않다면 3a 단계로 돌아감
4. hello-world-app 모듈에서 terraform destroy를 실행
5. mysql 모듈에서 terraform destroy를 실행

3단계에서 내부 루프를 신속하게 수행할 수 있는 능력은 테라폼을 사용한 빠르고 반복적인 개발의 핵심입니다.

이를 뒷받침하려면 테스트 코드를 여러 단계로 나누어야 합니다.

이 단계에서 실행할 단계와 건너 뛸 수 있는 단계를 선택할 수 있습니다.

테라테스트는 test_structure 패키지를 통해 이를 기본적으로 지원합니다.

테스트 단계를 사용하면 자동화된 테스트에서 빠른 피드백을 얻을 수 있기 때문에 반복적 개발의 속도와 품질이 크게 향상됩니다.

CI 환경에서는 테스트에 걸리는 시간에는 차이가 없겠지만 개발 환경에 미치는 영향은 큽니다.

### 재시도

인프라 코드에 대한 자동화된 테스트를 정기적으로 시작하면 비정상적인 테스트와 같은 문제가 발생할 수 있습니다.

즉, 때때로 EC2 인스턴스 시작에 실패하거나 테라폼의 최종 일관성 버그 또는 S3와의 TLS 핸드셰이크 오류와 같은 일시적인 이유로 테스트가 실패할 수 있습니다.

인프라 세계는 뒤죽박죽이므로 테스트가 간헐적으로 실패할 것으로 예상하고 적절히 처리해야 합니다.

테스트를 좀 더 탄력적으로 만들기 위해 알려진 오류에 대해 재시도를 추가할 수 있습니다.
## 종단 간 테스트(E2E)
### 테스트 피라미드

테라폼의 종단간 테스트도 다른 프로그래밍언어와 유사하게 진행됩니다.

통합 테스트와 동일한 전략으로 수십가지 테스트를 만들어 terraform apply를 실행하고 유효성 검증 후 terraform destroy를 수행하는 전략으로 종단 간 테스트를 작성할 수도 있지만 이러한 방법은 잘 쓰이지 않습니다.

그 이유는 테스트 피라미드와 관련이 있습니다.
![피라미드](./image/image1.png)
테스트 피라미드의 개념은 우리가 일반적으로 많은 수의 단위 테스트, 적은 수의 통합 테스트, 그리고 보다 더 적은 수의 종단 간 테스트를 목표로 해야 한다는 것입니다.

피라미드 위로 올라갈수록 테스트 작성의 비용과 복잡성, 테스트의 불안정성, 테스트 실행 시간이 모두 증가하기 때문입니다.

이전에 작성한 hello-world-app 모듈을 테스트하는데도 네임 스페이스, 종속성 주입, 재시도, 오류 처리 및 테스트 단계에 대한 상당한 양의 작업이 필요하다는 것을 확인했습니다.

더 크고 복잡한 인프라에서는 이러한 작업들이 더 어려워집니다.

그렇기때문에 가장 빠르고 안정적인 피드백 루프를 제공하기 위해 단위 테스트로 최대한 많은 코드를 작성하는 것을 추천합니다.

실제로 테스트 피라미드의 꼭대기에 다다를 무렵에는 2가지의 이유로 복잡한 아키텍처를 처음부터 배포하기 위한 테스트 실행이 불가능합니다.

- 너무 느림
    - 전체 아키텍처를 처음부터 배포한 다음 다시 취소하는데 대략 몇 시간 정도 걸릴 수 있습니다.
- 너무 취약함
    - 배포하는 인프라의 양이 증가함에 따라 간헐적이고 비정상적인 문제가 발생할 가능성도 높아집니다.

실제로 인프라가 복잡한 극소수의 기업만이 처음부터 끝까지 모든 것을 배포하는 종단간 테스트를 실행합니다.

종단 간 테스트에 대한 일반적인 테스트 전략은 다음과 같습니다.

1. 테스트라고 불리는 지속적이고 프로덕션과 유사한 환경 배포 비용을 한번만 지불하고 해당 환경을 실행 상태로 둡니다.
2. 누군가 인프라를 변경할 때마다 종단 간 테스트에서 다음을 수행합니다.
    1. 인프라 변경 사항을 테스트 환경에 적용
    2. 모든 것이 제대로 작동하는지 확인하기 위해 셀레니움을 사용하여 최종 사용자 관점에서 코드를 테스트하는 것 같이 테스트 환경 검증
    

종단 간 테스트 전략을 점진적 변경에만 적용하도록 변경하여 테스트 시간에 배포되는 리소스의 수를 수백 개에서 소수로 줄이면 이러한 테스트를 더 빠르고 안정적으로 수행합니다.

또한 종단 간 테스트에 대한 이러한 접근 방식은 변경 사항을 프로덕션 환경에 배포하는 방식과 더 밀접합니다.

결국 각 변경 사항을 롤아웃하기 위해 처음부터 프로덕션 환경을 분해하고 가져오는 것과는 다릅니다.

대신, 각 변경 사항을 점진적으로 적용하는 이러한 종단 간 테스트 스타일은 큰 이점을 제공합니다.

인프라가 올바르게 작동하는지 뿐만 아니라 해당 인프라에 대한 배포 프로세스가 올바르게 작동하는지도 테스트할 수 있습니다.
## 다른 테스트 접근 방식
### 다른 방식의 접근

테라테스트를 이용한 자동화 테스트를 사용하는데 중점을 두었지만 다음과 같이 다른 방식의 접근이 존재합니다.

- 정적 분석
- 속성 테스트

### 정적 분석

테라폼 코드를 실행하지 않고도 분석할 수 있는 몇가지 도구가 있습니다.

- terraform validate
    - 테라폼에 내장된 명령으로 테라폼 구문 및 유형을 확인하는 데 사용할 수 있습니다.
- tflint
    - 테라폼의 린트도구로 테라폼 코드를 스캔하고 내장 규칙 집합을 기반으로 일반적인 오류와 잠재적 버그를 포착할 수 있습니다.
- 하시코프 센티널
    - 다양한 하시코프 도구에 규칙을 적용할 수 있는 코드형 정책 프레임 워크입니다.
    - 예를 들어, 테라폼 코드에서 인바운드 액세스 0.0.0.0/0을 허용하는 보안 그룹 규칙을 불허하는 정책을 만들 수 있습니다.

### 속성 테스트

인프라의 특정 속성을 검증하는 데 중점을 둔 여러 테스트 도구가 있습니다.

- kitchen-terraform
- rspec-terraform
- serverspec
- inspec
- goss

이러한 도구의 대부분은 배포한 인프라가 어떤 사양을 준수하는지 확인하기 위해 간단한 도메인 특화 언어를 제공합니다.

예를 들어 EC2 인스턴스를 배포한 테라폼 모듈을 테스트하는 경우 다음 inspec 코드를 사용하여 인스턴스에 특정 파일에 대한 적절한 권한이 있고 특정 종속성이 설치되어 있으며 특정 포트에서 수신 대기 중인지 검증할 수 있습니다.

```go
describe file('/etc/myapp.conf') do
	it { should exist }
	its('mode') { should cmp 0644 }
end
```

이러한 테스트 도구의 장점은 도메인 특화 언어를 사용해 간결하고 사용하기 쉬우며 인프라의 많은 속성을 검증할수 있는 효율적이고 선언적인 방법을 제공한다는 것입니다.

이는 특히 PCI 컴플라이언스, HIPAA 컴플라이언스와 같은 규정 준수와 관련된 요구 사항의 체크리스트를 시행하는데 유용합니다.

이러한 도구의 단점은 모든 속성 확인이 통과되어도 인프라가 작동하지 않을 수 있다는 것입니다.

비교를 위해 동일한 속성을 검증하는 테라테스트 방식은 서버에 HTTP 요청을 하고 예상 응답을 다시 받는지 검증하는 것입니다.
## 테스트의 중요성
### 빠르게 변화하는 인프라

인프라는 계속해서 빠르게 변화하고 있습니다.

이는 인프라 코드가 매우 빠르게 부패한다는 것을 알 수 있으며, 자동화된 테스트가 없는 경우 인프라 코드의 손상을 빠르게 확인할 수 없습니다.

일일이 사람이 확인하면서 관리하는 것은 한계가 존재하며, 매번 인프라 코드를 작성할 때마다 코드를 클린하게 유지하고 수동으로 테스트하고 코드 리뷰를 하는데 아무리 많은 노력을 기울여도 자동화된 테스트를 실행하자마자 수많은 중대한 버그들을 발견하게 됩니다.

### 테스트를 통해 얻을 수 있는 점

테스트 프로세스를 자동화하는 데 시간을 할애하면 거의 예외 없이 여러분이 발견하지 못했던 문제들을 마법처럼 해결할 수 있습니다.

또한 처음 자동 테스트를 추가할 때 버그를 발견할 수 있을 뿐만 아니라 매번 커밋을 할 때마다 테스트를 실행하면 버그를 계속 발견할 수 있습니다.

그리고 인프라 코드에 추가한 자동화 테스트는 코드의 버그뿐만 아니라 테라폼, 패커, 엘라스틱 서치, 카프카, AWS 등 사용 중인 도구의 중대한 버그들도 발견하게 해줍니다.

### 자동화된 테스트의 어려움과 필요성

하지만 자동화된 테스트를 작성하는 것은 쉽지 않으며 이러한 테스트를 작성하려면 상당한 노력이 필요합니다.

테스트를 유지하고 신뢰할 수 있도록 충분한 재시도 로직을 추가하는 데는 더 많은 노력이 필요합니다.

게다가 비용을 통제하기 위해 테스트 환경을 클린하게 유지하려는 노력을 계속해야 합니다.

하지만 자동화된 테스트는 충분히 그럴만한 가치를 가지고 있습니다.

예를 들어, 데이터 저장소를 배포하기 위한 모듈을 구축할 때 모든 코드를 레포지터리에 커밋한 후에 테스트는 여러 구성에 데이터 저장소에 복사본을 만들고 데이터를 쓰고 읽은 다음 모든 것을 해체합니다.

해당 테스트가 통과될 때마다 코드가 여전히 작동한다는 확신이 생깁니다.

다른 특별한 일이 없다면 자동화된 테스트로 인해 추가적인 확인을 할 필요가 없게 됩니다.

### 테라폼 테스트시 주의사항

- 테라폼 코드를 테스트할 때는 로컬 호스트가 없습니다.
    - 따라서 실제 리소스를 하나 이상의 격리된 샌드박스 환경에 배포하여 모든 수동 테스트를 수행해야 합니다.
- 샌드박스 환경을 정기적으로 정리합니다.
    - 그렇지 않으면 환경을 관리할 수 없고 비용을 통제할 수 없습니다.
- 테라폼 코드에 대한 순수한 단위 테스트를 수행할 수 없습니다.
    - 따라서 실제 리소스를 하나 이상의 격리된 샌드박스 환경에 배포하는 코드를 작성하여 모든 자동화된 테스트를 수행해야 합니다.
- 모든 리소스의 네임 스페이스를 지정해야 합니다.
    - 이렇게 하면 병렬로 실행하는 여러 테스트가 서로 충돌하지 않습니다.
- 작은 모듈은 테스트하기 쉽고 빠릅니다.
    - 작은 모듈을 통해 유지 관리가 쉽고 재사용성을 높이고 테스트하기 쉬운 모듈을 만들 수 있습니다.