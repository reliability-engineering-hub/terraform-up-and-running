package test

import (
	"crypto/tls"
	"fmt"
	"github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/gruntwork-io/terratest/modules/random"
	"testing"
	"time"
)

func TestAlbExample(t *testing.T) {
	t.Parallel()
	
	opts := &terraform.Options{
		// alb 예제 디렉터리를 가리키도록 이 상대 경로를 업데이트해야 한다.
		TerraformDir: "../examples/alb",

		Vars: map[string]interface{}{
			"alb_name": fmt.Sprintf("test-%s", random.UniqueId()),
		},
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
