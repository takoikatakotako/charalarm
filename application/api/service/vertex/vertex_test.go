package vertex

import (
	"context"
	"testing"

	"github.com/stretchr/testify/assert"
)

// Lambda に渡す credential config (terraform/environment/development/main.tf) を読めること。
// トークンは最初の呼び出しで取るので、ここでは通信しない。
func TestNewHTTPClientWithCredentialConfig(t *testing.T) {
	config := `{
		"type": "external_account",
		"audience": "//iam.googleapis.com/projects/870183222406/locations/global/workloadIdentityPools/charalarm-aws/providers/development",
		"subject_token_type": "urn:ietf:params:aws:token-type:aws4_request",
		"token_url": "https://sts.googleapis.com/v1/token",
		"service_account_impersonation_url": "https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/charalarm-tts@sandbox-492513.iam.gserviceaccount.com:generateAccessToken",
		"credential_source": {
			"environment_id": "aws1",
			"regional_cred_verification_url": "https://sts.{region}.amazonaws.com?Action=GetCallerIdentity&Version=2011-06-15"
		}
	}`
	client, err := NewHTTPClient(context.Background(), config)
	assert.NoError(t, err)
	assert.NotNil(t, client)

	// external_account 以外は受け付けない
	_, err = NewHTTPClient(context.Background(), `{"type": "service_account"}`)
	assert.Error(t, err)
}
