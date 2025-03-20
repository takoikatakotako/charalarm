package repository

import (
	"context"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
)

type AWS struct {
	Profile string
}

// Private Methods
func (a *AWS) createAWSConfig() (aws.Config, error) {
	ctx := context.Background()

	if a.Profile == "" {
		// AWS環境の場合
		cfg, err := config.LoadDefaultConfig(ctx)
		if err != nil {
			return aws.Config{}, err
		}
		return cfg, nil
	} else if a.Profile == "local" {
		// CIなど Local Stack を利用する場合
		cfg, err := config.LoadDefaultConfig(ctx, config.WithRegion("ap-northeast-1"))
		if err != nil {
			return aws.Config{}, err
		}
		return cfg, nil
	} else {
		// プロファイルを利用する場合
		cfg, err := config.LoadDefaultConfig(ctx, config.WithSharedConfigProfile(a.Profile))
		if err != nil {
			return aws.Config{}, err
		}
		return cfg, nil
	}
}
