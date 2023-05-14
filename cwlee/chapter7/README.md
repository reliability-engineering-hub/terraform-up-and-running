# 07. 테라폼 코드 테스트

데프옵스 세계는 서비스 중단과 데이터 손실 그리고 보안 취약점에 대한 불안함 같은 두려움으로 가득 차 있다. </br>
코드형 인프라로 관리하는 경우 위험을 줄일 수 있는 더 좋은 방법이 있다. 바로 **테스트**이다. </br>
테스트의 목표는 변경에 대한 자신감을 주는 것이다. </br>
모든 인프라와 배포 프로세스를 코드로 정의할 수 있다면 프로덕션 준비 환경에서 코드를 테스트할 수 있고 준비 환경이 잘 작동한다면 동일한 코드를 프로덕션에 사용했을 때 역시 잘 작동할 가능성이 높다. </br>
이 장에서는 수동 테스트와 자동 테스트를 포함하여 인프라 코드 테스트 프로세스에 대해 살펴본다. </br>
```
- 수동 테스트
    - 기본 수동 테스트
    - 테스트 후 정리
- 자동화된 테스트
    - 단위 테스트
    - 통합 테스트
    - 종단 간 테스트
    - 다른 테스트 접근법
```

---

## 1. 수동 테스트
## 1.1 기본 수동 테스트
테라폼 코드를 테스트할 때 로컬 호스트가 없다. </br>
테라폼으로 수동 테스트를 수행할 수 있는 유일한 방법은 AWS같은 실제 환경에 배포하는 것이다. </br>
이는 각 모듈의 examples 폴더에 쉽게 배포할 수 있는 예제를 작성해야 하는 이유 중에 하나이다. </br>
- [examples/alb](./code/examples/alb/main.tf)
  ```
    provider "aws" {
        region  = "ap-northeast-2"
        version = "~> 2.0"
    }

    module "alb" {
        source     = "../../modules/networking/alb"
        alb_name   = "terraform-up-and-runnong"
        vpc_id     = data.aws_vpc.dev.id
        subnet_ids = data.aws_subnet_ids.default.ids
    }
  ```
  ALB에 다른 리스너 규칙이 구성되어 있지 않기 때문에 404 페이지를 반환한다.  </br>
  alb 모듈의 기본 동작이 404 페이지를 반환하는 점에 주의해야 한다. </br>
  ```
  $ curl -s -o /dev/null -w "%{http_code}" terraform-up-and-runnong-1329852482.ap-northeast-2.elb.amazonaws.com

  404
  ```
  기본 동작으로 401을 반환하도록 하는 등 변경 작업을 수행할 때마다 새로운 변경 사항을 배포하기 위해 `terraform apply`를 다시 실행한다. </br>
  ```
  $ curl -s -o /dev/null -w "%{http_code}" terraform-up-and-runnong-1329852482.ap-northeast-2.elb.amazonaws.com

  401
  ```
수동 테스트 과정에서 많은 인프라를 구축 및 해제하고 많은 실수를 겪을 가능성이 있으므로 이 환경은 스테이징, 프로덕션과 같은 다른 안정된 환경과 완전히 격리되어야 한다. </br>
따라서 모든 팀이 격리된 **샌드박스** 환경을 설정할 것을 권한다. 이 경우 개발자는 다른 샌드박스 환경에 영향을 줄 염려 없이 원하는 인프라를 구축하고 해체할 수 있다. </br>

</br>

## 1.2 테스트 후 정리
샌드 박스 환경울 정기적으로 정리해야 한다. </br>
테스트를 완료하면 `terraform destroy`를 실행하여 개발자가 배포한 모든 것을 정리하는 문화를 만들어야 한다. </br>
사용자의 배포 환경에 따라서 사용하지 않거나 오래된 리소스를 자동으로 정리하기 위해 크론 작업과 같이 정기적으로 실행할 수 있는 도구가 필요하다. </br>
다음과 같은 도구가 있다. </br>
```
- cloud-nuke
클라우드 환경의 모든 리소스를 삭제할 수 있는 오픈 소스 도구이다. 
주요 기능은 특정 기간보다 오래된 리소스를 삭제하는 것이다. 
예를 들어 일반적인 사용 패턴은 개발자가 수동 테스트를 위해 가동한 인프라가 2일 후에 더 이상 필요하지 않다는 가정 하에 각 샌드박스 환경에서 하루에 한 번씩 크론으로 cloud-nuke를 실행하여 2일 경과한 모든 리소스를 삭제한다.

$ cloud-nuke aws --older-than 48h

- Janitor Monkey
구성하는 일정에 따라 AWS 리소스를 정리하는 오픈 소스 도구이며 기본값은 주 1회이다.
리소스 정리 여부 및 삭제하기 며칠 전에 리소스 소유자에게 알림을 보내는 기능을 결정하는 구성 규칙도 지원한다.

- aws-nuke
AWS 계정에서 모든 것을 삭제하는 데 사용하는 오픈 소스 도구이다. 
YAML 구성 파일을 사용하여 삭제할 계정 및 리소스를 aws-nuke로 지정한다.

# 삭제할 리전을 지정
regions :
- us-east-2

# 삭제할 계정
accounts:
"1111111111" : {}

# 삭제할 리소스만 지정
resource-types:
targets :
- S3Object
- S3Bucket
- IAMRole

$ aws-nuke -c config.yml
```

---


## 2.자동화된 테스트
자동화된 테스트에는 다음과 같은 3가지 유형이 있다. </br>
- 단위 테스트
  - 단위 테스트는 하나의 작은 코드 단위의 기능을 검증한다.
  - 단위의 정의는 다양하지만 범용 프로그래밍 언어에서는 보통 단일 함수 또는 클래스이다.
  - 일반적으로 데이터베이스, 웹 서비스, 심지어 파일 시스템 같은 외부 종속성은 코드가 다양한 시나리오를 처리하는지 테스트하기 위해 `테스트 더블(test double)` 또는 테스트 더블 중 `목(mock)`으로 대체된다.
- 통합 테스트
  - 여러 단위가 함께 올바르게 작동하는지 확인한다.
  - 범용 프로그래밍 언어에서 통합 테스트는 여러 함수 또는 클래스가 함께 올바르게 작동하는지 확인하는 코드로 구성된다.
  - 통합 테스트는 일반적으로 실제 종속성과 목을 조합하여 사용한다.
  - 예를 들어 데이터베이스와 통신하는 앱의 일부를 테스트하는 경우 실제 데이터베이스를 사용하여 테스트하지만 앱의 인증 시스템과 같은 다른 종속성은 목으로 구현한다.
- 종단 간 테스트
  - 종단 간 테스트는 앱, 데이터 저장소, 로드 밸런서 같은 전체 아키텍처를 실행하고 시스템이 전체적으로 작동하는지 확인하는 과정을 포함한다.
  - 일반적으로 이러한 테스트는 웹 브라우저를 통해 제품과의 상호 작용을 자동화하기 위해 셀레니움을 사용하는 것과 같이 최종 사용자의 관점에서 수행된다.
  - 종단 간 테스트는 일반적으로 프로덕션을 반영하는 아키텍처에서 목 없이 실제 시스템을 사용한다.

</br>

각 유형의 테스트는 서로 다른 목적으로 사용되며 다양한 유형의 버그를 포착할 수 있기 때문에 세 가지 유형을 혼합하여 사용하는 경우가 많다. </br>

단위 테스트의 목적은 변경 사항에 대한 빠른 피드백을 얻고 다양한 순열을 검증하여 코드의 기본 빌딩 블록이 예상대로 작동하는지 확인할 수 있도록 빠른 테스트를 수행하는 것이다. </br>
그러나 개별 단위가 각각 올바르게 작동한다고 해서 결합 시 올바르게 작동한다는 의미는 아니다. </br>
따라서 기본 빌딩 블록이 올바르게 결합되로록 `통합 테스트`를 수행해야 한다. </br>
또한 시스템이 여러 부분이 올바르게 작동한다고 해서 실제 환경에 배포할 때 제대로 작동한다는 의미는 아니므로 프로덕션과 유사한 조건에서 코드가 예상대로 작동하는지 확인하려면 종단 간 테스트를 수행해야 한다. </br>

</br>

## 2.1 단위 테스트
```
class WebServer < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(request, response)
    case request.path
    when "/"
      response.status = 200
      response['Content-Type] = 'text/plain'
      response.body = 'Hello, World'
    when "/api"
      response.status = 201
      response['Content-Type'] = 'application/json'
      response.body = '{"foo":"bar"}'
    else
      response.status = 404
      response['Content-Type'] = 'text/plain'
      response.body = 'Not Found'
```
다음 코드를 수행해야 하므로 이 코드에 대한 단위 테스트 작성은 조금 까다롭다. </br>
1. WebServer 클래스를 인스턴스화한다. 전체 WEBrick HTTPServer 클래스를 전달하면서 AbstractServlet을 상속받는 WebServer의 생성자를 만드는 것은 생각보다 어렵다. </br>
이 목을 만들 수 있지만 정말 많은 작업을 해야 한다. 
2. HTTPRequest 유형의 request 객체를 생성한다. </br>
이 클래스를 인스턴스화하는 쉬운 방법은 없으며, 목을 만드는 데도 많은 작업을 해야 한다.
3. HTTPResponse 유형의 response 객체를 생성한다. </br>
다시 말하자만 이 클래스를 인스턴스화하는 쉬운 방법은 없으며 목을 만드는 데도 많은 작업을 해야 한다. </br>

단위 테스트를 작성하기 어려운 경우 코드 스멜일 가능성이 높으며 코드를 리팩터링해야 함을 나타낸다. </br>
이 루비 코드를 리팩터링하여 단위 테스트를 보다 쉽게 수행할 수 있는 한 가지 방법은 '핸들러(handler)', 즉 /, /api와 찾을 수 없는 경로를 처리하는 코드를 자체 Handlers 클래스로 추출하는 것이다. </br>

</br>

```
class Handlers
  def handler(path)
    case path
    when "/"
      [200, 'text/plain', 'Hello, World']
    when "/api"
      [201, 'application/json', '{"foo":"bar"}']
    else
      [404, 'text/plain', 'Not Found']
    end
  end
end
```

새로 등장한 이 Handlers 클래스에 대해 주목할 2가지 주요 특성이 있다. </br>
- 간단한 입력값
  - Handlers 클래스는 HTTPServer, HTTPRequest 또는 HTTPResponse에 의존하지 않는다. </br> 대신 모든 입력은 문자열은 URL path와 같은 기본 매개 변수이다.
- 간단한 출력값
  - Handlers 클래스는 메소드는 변경 가능한 HTTPResponse 객체에 값을 설정하는 대신 HTTP 응답을 HTTP 상태 코드, 컨텐츠 유형 및 본문을 포함하는 배열인 단순한 값을 반환한다. 

</br>
간단한 값을 입력으로 사용하고 간단한 값을 출력으로 반환하는 코드는 일반적으로 이해하기 쉽고 업데이트나 테스트하기 쉽다. </br>
먼저 새로운 Handlers 클래스를 사용하여 WebServer 클래스가 요청에 응답하도록 업데이트 한다. </br>

```
class WebServer < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(request, response)
    handlers = Handlers.new
    status_code, content_type, body = handlers.handler(request.path)

    response.status = status_code
    response['Content-Type'] = content_type
    response.body = body
  end
end
```

</br>

각 엔드 포인트에 대한 단위 테스트는 다음과 같다. </br>
```
class TestWebServer < Test::Unit:TestCase
    def initialize(test_method_name)
        super(test_method_name)
        @handlers = Handlers.new
    end

    def test_unit_hello
        status_code, content_type, body = @handlers.handler("/")
        assert_equal(200, status_code)
        assert_equal('text/plain', content_type)
        assert_equal('Hello, World', body)
    end

    def test_unit_api
        status_code, content_type, body = @handlers.handler("/")
        assert_equal(200, status_code)
        assert_equal('application/json', content_type)
        assert_equal('{"foo":"bar"}', body)
    end

    def test_unit_404
        status_code, content_type, body = @handlers.handler("/invalid-path")
        assert_equal(404, status_code)
        assert_equal('text/plain', content_type)
        assert_equal('Not Found', body)
    end    
end   
```
단위 테스트의 장점은 코드에 대한 신뢰를 높이는 데 도움이 되는 빠른 피드백 루프이다. </br>
실수로 /api 엔드포인트의 응답을 변경하는 것 같이 코드 작성 과정에 실수가 있다면 그 사실을 거의 즉시 알 수 있다. </br>

### 단위 테스트의 기본 사항
테라폼에서 단일 함수 또는 클래스와 가장 가까운 것은 단일 일반 모듈이다. </br>
테라폼 코드가 수행하는 작업의 99%가 복잡한 종속성과 통신하는 것이다. </br>
외부 종속성의 수를 0으로 줄일 수 있는 방법은 사실상 없으며 줄인다 하더라도 결국 테스트할 코드가 남아 있지 않을 것이다. </br>
따라서 테라폼 코드에 대한 순수한 단위 테스트를 수행할 수 없다. </br>

</br>

인프라를 AWS 계정 같은 실제 환경에 배포하는 자동화된 테스트를 작성하여 테라폼 코드가 예상대로 작동할 것이라는 자신값을 가진 수 있다. </br>
즉, 테라폼의 단위 테스트는 실제 통합 테스트이다.

</br>

테라폼에 대한 단위 테스트를 작성하는 기본 전략은 다음과 같다. </br>
```
1. 일반 독립형 모듈을 작성한다.
2. 해당 모듈에 대한 배포하기 쉬운 예제를 작성한다.
3. terraform apply를 실행하여 예제를 실제 환경에 배포한다.
4. 방금 배포한 모듈이 예상대로 작동하는지 검증한다. 이 단계는 테스트 중인 인프라 유형에 따라 다르다. 예를 들어 ALB의 경우 HTTP 요청을 보내고 예상 응답이 다시 수신되는 확인하여 ALB를 검증한다.
5. 테스트가 끝나면 terraform destroy를 실행하여 정리한다.
```
즉, 수동 테스트를 수행할 때와 동일한 단계를 수행하지만 해당 단계를 코드로 캡쳐한다. </br>
실제로 이는 테라폼 코드에 대한 자동화된 테스트를 생성하기 위한 좋은 멘탈 모델이다. </br>

</br>

### 테라테스트 예시
1. terraform.Options를 사용하여 테라테스트를 테라폼 코드가 있는 위치로 지정한다.
2. terraform init 및 terraform apply를 실행하여 코드를 배포한다. (헬퍼 함수 사용)
3. terraform output을 이용해 출력 변수 읽는다.
4. ALB에 반복적으로 HTTP 요청한다.
   - 비동기적, 최종 일관성 동작에 대해 재시도 내용을 추가한다.
   - http_helper.HttpGetWithRetry 메소드는 예상 상태 코드 또는 본문을 다시 가져오지 않으며, </br> 지정된 재시도 간격으로 지정된 최대 횟수까지 재시도한다.
5. terraform destroy를 실행한다. (헬퍼 함수 사용)
   - 테스트가 실패하더라도 terraform destroy를 실행하도록 하기 위해 defer문을 추가한다.
     - defer문은 서라운딩 함수가 어떤 값을 반환하든 defer문으로 정의된 코드가 실행되도록 보장한다.
   - defer가 terraform.InitAndApply를 호출하기도 전인 코드 초기에 추가되었다. </br> 이는 defer 명령문에 도달하기 전에 테스트가 실패하지 않도록 하고 terraform.Destroy 호출이 수행되지 않도록 방지한다.
```
func TestAlbExample(t *testing.T) {
	opts := &terraform.Options{
		// alb 예제 디렉터리를 가리키도록 이 상대 경로를 업데이트해야 한다.
		TerraformDir: "../examples/alb",
	}

	// 테스트가 종료되면 모든 것을 삭제한다.
	defer terraform.Destroy(t, opts)

	// 예제 배포
	terraform.InitAndApply(t, opts)

	// ALB의 URL 정보 가져오기
	albDnsName := terraform.OutputRequired(t, opts, "alb_dns_name")
	url := fmt.Sprintf("http://%s", albDnsName)

	// ALB의 기본 동작이 작동하고 404 반환하는지 확인

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

### 종속성 주입
코드를 있는 그대로 테스트하려고 하면 단위 테스트는 외부 종속성의 영향을 받는다.
- 해당 종속성과 통신하는 데 장애가 있으면 코드에 아무런 문제가 없더라도 테스트가 실패한다.
- 해당 종속성이 다른 응답 본문을 반환하는 것 같이 이따금 동작을 변경한 경우 테스트가 종종 실패하며 구현에 아무런 문제가 없더라도 테스트 코드를 지속적으로 업데이트 해야한다.
- 이러한 종속성이 느리면 테스트 속도가 느려져 단위 테스트의 주요 이점 중 하나인 빠른 피드백 루프가 무효화된다.
- 코드가 리디렉션을 처리하는지 여부처럼 종속성이 어떻게 작동하는가에 따라 코드가 다양한 코너 케이스5 사례를 처리하는지 테스트하려는 경우 외부 종속성을 제어하지 않으면 코드를 처리할 수 없다.

</br>

실제 종속성을 사용하여 작업하는 것이 통합이나 종단 간 테스트에 적합할 수 있지만 단위 테스트의 경우 외부 종속성을 가능한 최소화해야 한다. </br>
이를 수행하는 일반적인 전략은 `종속성 주입`으로써 코드 내에서 하드 코딩하지 않고 코드 외부에서 외부 종속성을 전달할 수 있다. </br>

</br>


테라폼에서 외부 종속성이 0인 순수한 단위 테스트를 수행할 수 없지만 가능한 외부 종속성을 최소화하는 것이 좋다. </br>
종속성을 최소화하는 첫 번째 단계는 모듈의 종속성을 명확하게 하는 것이다. </br>
외부 종속성을 나타내는 모든 데이터 소스와 리소스를 별도의 `dependencies.tf`파일로 이동해 분리한다. </br>
```
data "aws_vpc" "default" {
  id = var.vpc_id
}

# get all subnets from aws vpc
data "aws_subnet_ids" "default" {
  # set vpc_id from data (aws_vpc)
  vpc_id = data.aws_vpc.default.id
}

data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    region = "ap-northeast-2"
    bucket = var.db_remote_state_bucket
    key    = var.db_remote_state_key
  }
}

data "template_file" "user_data" {
  template = file("${path.module}/user-data.sh")

  vars = {
    server_port = var.server_port
    db_address  = data.terraform_remote_state.db.outputs.address
    db_port     = data.terraform_remote_state.db.outputs.port
    server_text = var.server_text
  }
}
```
외부 종속성을 별도의 파일로 표현함으로써 코드 사용자는 이 코드가 외부 세계에서 어디에 의존하는지 한눈에 쉽게 알 수 있다. </br>
테스트를 수행할 때 해당 부분을 교체할 수 있도록 `입력 변수`를 사용해 모듈 외부에서 이러한 종속성을 주입할 수 있다. </br>

</br>

각 변수는 default는 'null'값을 사용한다. default값을 vpc_id의 빈 문자열 또는 subnet_id의 빈 리스트처럼 비어 있는 값으로 설정하면 </br> 
기본값으로 빈 값을 설정했는지 또는 사용자가 의도적으로 빈 값을 전달했는지 구분할 수 없다. </br> 
null 값은 변수가 설정되지 않았거나 사용자가 기본 동작으로 돌아가고자 함을 명확히 나타내므로 이러한 경우 유용하다. </br>
```
variable "vpc_id" {
  description = "The ID of the VPC to deploy into"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "The IDS of the subnets to deploy into"
  type        = list(string)
  default     = null
}

variable "mysql_config" {
  description = "The config for the MySQL DB"
  type = object({
    address = string
    port    = number
  })
  default = null
}
```

</br>

VPC_ID, 서브넷 ID 및 MySQL 구성에 대한 입력 변수가 있다. 각 변수는 default를 지정하므로 사용자가 default 값을 얻기 위해 사용자 정의하거나 생략할 수 있는 선택적 변수이다. </br>
각 변수는 `null`값을 사용한다. default값을 vpc_id의 빈 문자열 또는 subnet_id의 빈리스트처럼 비어 있는 값으로 설정하면 기본값으로 빈 값을 설정했는지 또는 사용자가 의도적으로 빈 값을 전달했는지 구분할 수 없다. </br>
`null` 값은 변수가 설정되지 않았거나 사용자가 기본 동작으로 돌아가고자 함을 명확히 나타내므로 이러한 경우에 유용하다. </br>

</br>

1. `db_remote_state_bucket`과 `db_remote_state_key` 입력 변수가 null로 설정되어 있는지 여부에 따라 3개 데이터 소스를 선택적으로 생성하도록 count 매개 변수를 사용한다.
2. 입력 변수나 데이터 소스를 조건부로 사용하기 위해 데이터 소스에 대한 참조를 로컬 값으로 묶어 업데이트한다.
3. 코드를 살펴보고 이러한 데이터 소스 중 하나에 대한 참조를 찾는다면 해당 부분을 로컬 값에 대한 참조로 변경한다.
```
data "aws_vpc" "default" {
  count   = local.vpc_id == null ? 1 : 0
  default = true
}

# get all subnets from aws vpc
data "aws_subnet_ids" "default" {
  count = local.subnet_ids == null ? 1 : 0
  # set vpc_id from data (aws_vpc)
  vpc_id = local.vpc_id
}

data "terraform_remote_state" "db" {
  count   = local.mysql_config == null ? 1 : 0
  backend = "s3"

  config = {
    region = "ap-northeast-2"
    bucket = var.db_remote_state_bucket
    key    = var.db_remote_state_key
  }
}

locals {
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

  mysql_config = (
    var.mysql_config == null
    ? data.terraform_remote_state.db[0].outputs
    : var.mysql_config
  )
}
```

</br>

terraform.Options의 Vars 매개 변수를 사용하면 테라폼 코드에 변수를 설정할 수 있다. </br>
[이 코드](../chapter7/code/test/hello_world_app_example_test.go)는 mysql_config 변수에 대한 일부 목 데이터를 전달합니다. </br>

</br>

해당 테스트만 실행할 -run 인수를 지정한 go test 명령어를 사용하여 테스트를 진행한다.
```
go test -v timeout 30m -run TestHelloWorldAppExample₩

--- PASS: TestHelloWorldAppExample (326.14s)
PASS
ok      command-line-arguments  327.071s
```

---

### 병렬로 테스트 실행

인프라 코드에서 단일 테스트를 실행하는 데 걸리는 4~5분 정도의 시간은 길지는 않다. </br>
그러나 수십 개의 테스트가 있고 각 테스트가 순차적으로 실행되는 경우 전체 테스트 묶음을 실행하는 데 몇 시간이 걸릴 수 있다. </br>
피드백 루프를 줄이려면 가능한 한 많은 테스트를 병령로 실행해야 한다. </br>

Go에 테스트를 병렬로 실행하도록 지시하려면 각 테스트 상단에 t.Parallel()만 추가하면 된다.
```
func TestHelloWorldAppExample(t *testing.T) {
	t.Parallel()
	
	opts := &terraform.Options{
		TerraformDir: "../examples/hello-world-app/standalone",
		Vars : map[string]interface{} {
			"mysql_config" : map[string]interface{}{
				"address" : "mock-value-for-test",
				"port" : 3306,
			},
		},
	}

 // (...)
```
go test를 실행하면 다수의 테스트가 병렬로 실행된다. 그러나 ASG, 보안 그룹 및 ALB와 같이 해당 테스트에서 생성된 일부 리소스는 동일한 이름을 사용하므로 이름 충돌로 인해 테스트가 실패한다. </br>
이는 테스트 시의 네 번째 중요 사항으로 이어진다. 넷째, 모든 리소스의 네임스페이스를 지정해야 한다. </br>
즉, 모든 리소스의 이름을 선택적으로 구성할 수 있도록 모듈 및 예제를 디자인한다. </br>

</br>

1. 새 입력 변수를 할당한 기본값과 함께 추가한다.
```
variable "alb_name" {
  description = "The name of the ALB and all its resource"
  type        = string
  default     = "terraforming-up-and-running"
}
```

2. alb 모듈에 값을 전달한다.
```
module "alb" {
  source      = "../../modules/networking/alb"

  alb_name    = var.alb_name
  subnets_ids = data.aws_subnet_ids.default.ids
}
```

3. alb_example_test.go에서 이 변수를 고유한 값으로 설정한다.
```
func TestAlbExample(t *testing.T) {
  t.Parallel()

  opts := &terraform.Options {
    TerraformDir: "../examples/alb",

    Vars: map[string]interface{} {
      "alb_name": fmt.Sprintf("test-%s", random.UniqueId())
    },
  }

  // (...)
}
```

4. examples/hello-world-app/variables.tf에 새로운 입력 변수를 추가한다.
```
variable "environment" {
  description = "The name of the environment we're deploying to"
  type        = string
  default     = "example"
}
```

5. 해당 변수를 [hello-word-app](../chapter7/code/modules/services/hello-world-app/main.tf) 모듈에 전달한다.
6. [hello_world_app_example_test.go](../chapter7/code/test/hello_world_app_example_test.go)에 random.UniqueId()를 포함하는 environment를 값으로 설정한다.
7. `go test -v timeout 30m`

두 테스트가 동시에 실행되므로 전체 테스트를 하는 데는 각 테스트에 걸리는 시간을 연이어 합한 시간이 아니라 가장 오래 걸리는 테스트 시간만큼만 소요된다. </br>
기본적으로 Go가 병렬로 실행할 테스트 수는 컴퓨터에 있는 CPU 수와 같다. </br>
따라서 CPU가 하나뿐인 경우 기본적으로 테스트는 병렬이 아닌 순차적으로 실행된다. </br>
GOMAXPROCS 환경 변수를 설정하거나 -parallel인수를 go test 명령에 전달하여 이 설정을 대체할 수 있다. </br>
예를 들어 Go가 2개의 테스트를 동시에 실행하도록 하려면 다음과 같이 설정한다. </br>
```
$ go test -v -timeout 30m -parallel 2
```

---

## 2.2 통합 테스트
테라폼 단위가 단위 모듈인 경우 여러 단위가 함께 작동하는 방식을 검증하는 통합 테스트는 여러 모듈을 배포하고 제대로 작동하는지 확인해야 한다. </br>
이전 절에서는 실제 MySQL DB 대신 목 데이터와 함께 'Hello, World' 앱 예제를 배포했다. </br>
통합 테스트를 위해 MySQL 모듈을 실제로 배포하고 'Hello, World' 앱이 올바르게 통합되는지 확인해보자. </br>

테스트는 다음과 같이 구성된다.
1. mysql 배포
2. hello-world-app 배포
3. 앱 유효성 검증
4. hello-world-app 배포 취소
5. mysql 배포 취소

지금까지 backend 구성은 하드 코딩된 값으로 설정되었다. </br>
이러한 하드 코딩된 값은 테스트할 때 큰 문제가 된다. </br>
이 값을 변경하지 않으면 스테이징을 위한 값이 실제 상태 파일을 덮어쓰기 때문이다. </br>
이를 해결하기 위해 전체 backend 구성을 backend.hcl와 같은 외부 파일로 이동한다. </br>
```
terraform init -backend-config=backend.hcl
``` 

</br>

mysql 모듈에서 테스트를 실행할 때 terraform.Options의 BackendConfig 매개 변수를 사용하여 테라테스트에 테스트 시간이 표현된 형태로 값을 전달하도록 지시할 수 있다. </br>
```
func createDbOpts(t *testing.T, terraformDir string) *terraform.Options {
	uniqueId := random.UniqueId()

	bucketForTesting := "YOUR_S3_BUCKET_FOR_TESTING"
	bucketRegionForTesting := "YOUR_S3_BUCKET_REGION_FOR_TESTING"
	dbStateKey := fmt.Sprint("%s/%s/terraform.tfstate".t.Name(), uniqueId)

	return &terraform.Options{
		TerraformDir: terraformDir,

		Vars: map[string]interface{}{
			"db_name":     fmt.Sprintf("test%s".uniqueId),
			"db_password": "password",
		},

		BackendConfig : map[string]interface{}{
			"bucket" : bucketForTesting,
			"region" : bucketRegionForTesting,
			"key" : dbStateKey,
			"encrypt" : true,
		}
	}
}
```

다음과 같이 db_remote_state_bucket 및 db_remote_state_key는 mysql 모듈의 BackendConfig에서 사용되는 값으로 설정된다. </br>
```
func createHelloOpts(
	dbOpts *terraform.Options,
	terraformDir string) *terraform.Options {
	return &terraform.Options{
		TerraformDir: terraformDir,

		Vars: map[string]interface{}{
			"db_remote_state_bucket": dbOpts.BackendConfig["bucket"],
			"db_remote_state_key":    dbOpts.BackendConfig["key"],
			"environment":            dbOpts.Vars["db_name"],
		},
	}
}
```

마지막으로 [validateHelloApp]() 메소드를 구현한다. </br>
http_helper 패키지를 사용한다. HTTP 응답 상태 코드 및 본문에 대한 사용자 정의 유효성 검증 규칙을 지정할 수 있는 </br>
`http_helper.HttpGetWithRetryWithCustomValidation` 메소드를 사용한다. </br>
```
func validateHelloApp(t *testing.T, helloOpts *terraform.Options) {
	albDnsName := terraform.OutputRequired(t, helloOpts, "alb_dns_name")
	url := fmt.Sprintf("httpL//%s", albDnsName)

	maxRetries := 10
	timeBetweenRetries := 10 * time.Second

	http_helper.HttpGetWithRetryWithCustomValidation(
		t,
		url,
		&tls.Config{},
		maxRetries,
		timeBetweenRetries,
		func(status int, body string) bool {
			return status == 200 &&
				strings.Contains(body, "Hello, World")
		},
	)
}
```

</br>

### 테스트 단계
통합 테스트를 위한 코드를 살펴보면 5가지 '단계'로 구성되어 있음을 알 수 있다.
1. mysql 모듈에서 terraform apply 실행
2. hello-world-app 모듈에서 terraform apply 실행
3. 유효성 검증을 실행하여 모든 것이 작동하는지 확인
4. hello-world-app 모듈에서 terraform destroy를 실행
5. mysql 모듈에서 terraform destroy를 실행


CI 환경에서 이러한 테스트를 실행하면 처음부터 끝까지 모든 단계를 실행해야 한다. </br>
그러나 코드를 반복적으로 변경하면서 로컬 개발 환경에서 이러한 테스트를 실행하는 경우 </br>
모든 단계를 실행할 필요가 없다. </br>
예를 들어 hello-world-app 모듈만 변경하는 경우에도 모든 변경 사항마다 전체 테스트를 다시 실행한다면 변경이 아무 영향을 미치지 않더라도 mysql 모듈을 배포하고 취소하는 비용을 지불해야한다. </br>
이때 모든 테스트 실행에 5~10분의 오버헤드가 추가된다. </br>

</br>

이상적인 워크플로는 다음과 같다.
1. mysql 모듈에서 terraform apply를 실행
2. hello-world-app 모듈에서 terraform apply를 실행
3. 개발 과정 반복
  1. hello-world-app 모듈을 변경
  2. hello-world-app 모듈에서 terraform apply를 다시 실행하여 업데이트를 배포
  3. 유효성 검증을 실행하여 모든 것이 작동하는지 확인
  4. 모든 것이 작동하면 다음 단계로 넘어감. 그렇지 않으면 3a 단계로 돌아감
4. hello-world-app 모듈에서 terraform destroy를 실행
5. mysql 모듈에서 terraform destroy를 실행

3단계에서 내부 루프를 신속하게 수행할 수 있는 능력은 테라폼을 사용한 빠르고 반복적인 개발의 핵심이다. </br>
이를 뒷받침하려면 테스트 코드를 여러 단계로 나누어야 한다. </br>
이 단계에서 실행할 단계와 건너 뛸 수 있는 단계를 선택할 수 있다. </br>
테라테스트는 test_structure 패키지를 통해 이를 기본적으로 지원한다. </br>
각 테스트 단계는 후속 테스트 실행 시 디스크에서 다시 읽을 수 있도록 테스트 데이터를 디스크에 저장한다. </br>
```
func TestHelloWorldAppStageWithStages(t *testing.T) {
	t.Parallel()

	stage := test_structure.RunTestStage

	// MySQL DB 배포
	defer stage(t, "teardown_db", func() { teardownDb(t, dbDirStage) })
	stage(t, "deploy_db", func() { deployDb(t, dbDirStage) })

	// hello-world-app 배포
	defer stage(t, "teardown_app", func() { teardownApp(t, appDirStage) })
	stage(t, "deploy_app", func() { deployApp(t, appDirStage) })

	// hello-world-app 유효성 검증
	stage(t, "validate_app", func(){ validateApp(t, appDirStage)})
}
```
`RunTestStage` 메소드는 세 가지 인수를 사용한다. </br>
- t
  - 첫 번쨰 인수는 Go가 모든 자동화된 테스트에 대한 인수로 전달하는 t값이다.
- 단계 이름
  - 두 번째 인수를 사용하면 이 테스트 단계의 이름을 지정할 수 있다.
- 실행할 코드
  - 세 번째 인수는 이 테스트 단계에서 실행할 코드이다.


다른 테스트 단계에서 나중에 읽을 수 있도록 test_structure.SaveTerraformOptions 함수를 이용해 dbOpts의 데이터를 디스크에 기록한다. </br>
```
func deployDb(t *testing.T, dbDir string) {
	dbOpts := createDbOpts(t, dbDir)

	// 나중에 실행되는 다른 테스트 단계에서 데이트를 다시 읽을 수 있도록 데이터를 디스크에 저장
	test_structure.SaveTerraformOptions(t, dbDir, dbOpts)
	terraform.InitAndApply(t, dbOpts)
}
```

</br>

test_structure.LoadTerraformOptions를 사용하여 deployDb 함수로 이전에 저장된 디스크에서 dbOpts 데이터를 로드한다. </br>
```
func teardownDb(t *testing.T, dbDir string) {
	dbOpts := test_structure.LoadTerraformOptions(t, dbDir)
	defer terraform.Destroy(t, dbOpts)
}
```

</br>
전체 테스트 코드는 원래 통합 테스트 동일하다. </br>
이떄 각 단계가 test_structure.RunTestStage에 대한 호출로 래핑된다는 점과 디스크에서 데이터를 저장하고 로드하기 위해 약간의 작업이 필요하다는 점이 다르다. </br>
환경 변수 SKIP_foo = true를 설정하여 테라테스트가 foo라는 테스트 단계를 건너뛰도록 지시할 수 있다. </br>
```
$ SKIP_teardown_db=true \
  SKIP_teardown_app=true \
  go test -timeout 30m -run 'TestHelloWorldAppStageWithStages'
```

</br>

테스트 단계를 사용하면 자동화된 테스트에서 빠른 피드백을 얻을 수 있으므로 반복적 개발의 속도와 품질이 크게 향상된다. </br>
CI 환경에서 테스트에 걸리는 시간에는 차이가 없지만 개발 환경에 미치는 영향은 크다. </br>

### 재시도
인프라 코드에 대한 자동화된 테스트를 정기적으로 시작하면 비정상적인 테스트와 같은 문제가 발생할 수 있다. </br>
인프라 세계는 뒤죽박죽이므로 테스트가 간헐적으로 실패할 것으로 예상하고 적절히 처리해야 한다. </br>
테스트를 좀 더 탄력적으로 만들기 위해 알려진 오류에 대한 재시도를 추가할 수 있다. </br>
오류가 발생할 때 테스트의 안정성을 높이기 위해 terraform.Options의 MaxRetries, TimeBetweenRetries, RetryableTerraformErrors 인수를 사용하여 테라테스트에서 재시도를 활성화할 수 있다. </br>

```
func createHelloOpts(
	dbOpts *terraform.Options,
	terraformDir string) *terraform.Options {
	return &terraform.Options{
		TerraformDir: terraformDir,

		Vars: map[string]interface{}{
			"db_remote_state_bucket": dbOpts.BackendConfig["bucket"],
			"db_remote_state_key":    dbOpts.BackendConfig["key"],
			"environment":            dbOpts.Vars["db_name"],
		},

		// 알려진 오류가 발생하면 테스트를 5초 간격으로 최대 3번 재시도
		MaxRetries: 3,
		TimeBetweenRetries: 5 * time.Second,
		RetryableTerraformErrors: map[string]string{
			"RequestError: send request failed" : "Throttling issue?",
		},
	}
}
```

---

## 2.3 종단 간 테스트
종단 간 테스트는 프로덕션을 모방하는 환경에 모든 것을 배포하고 최종 사용자의 관정에서 테스트한다. </br>
통합 테스트와 동일한 전략, 즉 수십 가지 테스트 단계를 만들어 terraform apply를 실행하고 유효성 검증 후 terraform destroy를 수행하는 전략으로 종단 간 테스트를 작성할 수 있지만 이 방법은 거의 쓰이지 않습니다. </br>
<img src="./img/1.png" width="55%" height="55%"/> </br>
테스트 피라미드의 개념은 우리가 일반적으로 많은 수의 단위 테스트, 적은 수의 통합 테스트 그리고 보다 더 적은 수의 종단 간 테스트를 목표로 해야 한다는 것이다. </br>
피라미드 위로 올라갈수록 테스트 작성의 비용과 복잡성, 테스트의 불안정성, 테스트 실행 시간이 모두 증가하기 때문이다. </br>
이를 통해서 테스트 시 다섯 번째 중요 사항을 확인할 수 있다. </br>
다섯째, 더 작은 모듈은 더 쉽고 빠르게 테스트할 수 있다. </br>

</br>

크고 복잡한 인프라에서 테스트 작업을 어려워진다. 피라미드의 아래가 가장 빠르고 가장 안정적인 피드백 루프를 제공하기 때문에 우리는 많은 테스트를 가능한 한 피라미드의 아래에서 수행하려고 한다. </br>
실제로 테스트 피라미드의 꼭대기에 다다를 무렵에는 2가지 주된 이유로 인해 복잡한 아키텍처를 처음부터 배포하기 위한 테스트 실행이 불가능해진다. </br>
- 너무 느림
  - 전체 아키텍처를 처음부터 배포한 다음 배포를 취소하는 데 대략 몇 시간 정도 걸릴 수 있다. </br>
    피드백 루프가 너무 느리기 때문에 시간이 오래 걸리는 테스트 묶음은 상대적으로 적은 가치를 제공한다. 
- 너무 취약함
  - 단일 리소스를 배포하는 테스트가 간헐적인 오류 없이 실행될 확률은 99.9%이다. </br>
    재시도 중에 오료 중 일부를 처리할 수 있지만 이것은 곧 끝나지 않는 두더지 게임으로 바뀐다. </br>

실제로 인프라가 복잡한 극소수의 기업만이 처음부터 끝까지 모든 것을 배포하는 종단 간 테스트를 실행한다. </br>
종단 간 테스트에 대한 보다 일반적인 테스트 전략은 다음과 같다. </br>

1. '테스트'라고 불리는 지속적이고 프로덕션과 유사한 환경 배포 비용을 한 번만 지불하고 해당 환경을 실행 상태로 둔다. 
2. 누군가 인프라를 변경할 때마다 종단 간 테스트에서 다음을 수행한다.
   1. 인프라 변경 사항을 테스트 환경에 적용
   2. 모든 것이 제대로 작동하는지 확인하기 위해 셀레니움을 사용하여 최종 사용자 관점에서 코드를 테스트하는 것 같이 테스트 환경 검증


종단 간 테스트 전략을 점진적 변경에만 작용하도록 변경하여 테스트 시간에 배포되는 리소스 수를 소수로 줄이면 이러한 테스트를 더 빠르고 안정적으로 수행한다. </br>

</br>

### 무중단 배포 검증하기
1. 테라테스트의 http_helper.ContinuouslyCheckUrl 헬퍼를 사용하여 매초마다 주어진 ALB URL에 HTTP GET을 수행하고 200 OK가 아닌 응답을 수신하면 테스트에 실패하는 고루틴을 백그라운드에서 실행
2. 새 server_text 변수를 업데이트하고 terraform apply를 샐행하여 롤링 배포를 시작
3. 배포가 완료되면 서버가 새로운 server_text 값으로 응답하는지 확인
4. ALB URL을 지속적으로 확인하는 고루틴을 중지
```
func redeployApp(t *testing.T, helloAppDir string) {
	helloOpts := test_structure.LoadTerraformOptions(t, helloAppDir)

	albDnsName := terraform.OutputRequired(t, helloOpts, "alb_dns_name")
	url := fmt.Sprintf("http://%s", albDnsName)

	stopChecking := make(chan bool, 1)
	waitGroup, _ := http_helper.ContinuouslyCheckUrl(
		t,
		url,
		stopChecking,
		1*time.Second,
	)

	// 서버 텍스트를 업데이트하고 재배포
	newServerText := "Hello, World, v2!"
	helloOpts.Vars["server_text"] = newServerText
	terraform.Apply(t, helloOpts)

	// 새 버전이 배포되었는지 확인
	maxRetries := 10
	timeBetweenRetries := 10 * time.Second
	http_helper.HttpGetWithRetryWithCustomValidation(
		t,
		url,
		&tls.Config{},
		maxRetries,
		timeBetweenRetries,
		func(status int, body string) bool {
			return status == 200 &&
				strings.Contains(body, newServerText)
		},
	)

	// 검사 중지
	stopChecking <- true
	waitGroup.Wait()
}
```

</br>

### 다른 테스트 접근 방식
서로 다른 유형의 자동화된 테스트가 다른 유형의 버그를 포착하는 것처럼 이러한 각 테스트 접근 방식 역시 서로 다른 유형의 버그를 포학하므로, </br>
최상의 결과를 얻기 위해 여러 개를 함께 사용할 수 있다.
- 정적 분석
  - 테라폼 코드를 실행하지 않고도 분석할 수 있는 몇 가지 도구가 있다.
    1. terraform validate
      - 테라폼에 내장된 명령으로 테라폼 구문 및 유형을 확인하는 데 사용할 수 있다.
    2. tflint
      - 테라폼 코드를 스캔하고 내장 규칙 집합을 기반으로 일반적인 오류와 잠재적 배그를 포착할 수 있다.
    3. 해시코프 센티널
- 속성 테스트
  - 인프라의 특정 '속성'을 검증하는 데 중점을 둔 여러 테스트 도구가 있다.
    1. kitchen-terraform
    2. rspec-terraform
    3. serverspec
    4. inspec
    5. goss
  - 이러한 도구의 대부분은 배포한 인프라가 어떤 사양을 준수하는지 확인하기 위해 간단한 도메인 특화 언어를 사용한다.

---

## 3. 결론
인프라 세계의 모든 것은 지속적으로 변화하고 있다. 이는 인프라 코드가 매우 빨리 부패한다는 것을 의미한다.

</br>

```
자동화된 테스트가 없는 인프라 코드는 손상되기 쉽습니다.
```

자동화된 테스트를 작성하는 것은 쉽지 않으며 이러한 테스트를 작성하려면 상당한 노력이 필요하다. </br>
테스트를 유지하고 신뢰할 수 있도록 충분한 재시도 로직을 추가하는 데는 더 많은 노력이 필요하다. </br>
게다가 비용을 통제하기 위해 테스트 환경을 클린하게 유지하려는 노력을 계속해야 한다. </br>
하지만, **충분히 그럴 만한 가치**가 있다. </br>