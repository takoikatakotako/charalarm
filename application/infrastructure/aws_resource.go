package infrastructure

import (
	"context"
	"fmt"
	"strconv"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/cloudfront"
	cftypes "github.com/aws/aws-sdk-go-v2/service/cloudfront/types"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

// ResourceFile はキャラのリソース (S3 の {charaID}/ 以下) のファイル。
type ResourceFile struct {
	FileName     string
	Size         int64
	LastModified time.Time
}

func (a *AWS) createS3Client() (*s3.Client, error) {
	cfg, err := a.createAWSConfig()
	if err != nil {
		return nil, err
	}
	if a.Profile == "local" {
		return s3.NewFromConfig(cfg, func(o *s3.Options) {
			o.BaseEndpoint = aws.String(LocalstackEndpoint)
			o.UsePathStyle = true
		}), nil
	}
	return s3.NewFromConfig(cfg), nil
}

// ListResourceFiles は bucket の {charaID}/ 直下のファイルを返す。
func (a *AWS) ListResourceFiles(bucket string, charaID string) ([]ResourceFile, error) {
	client, err := a.createS3Client()
	if err != nil {
		return nil, err
	}

	prefix := charaID + "/"
	files := make([]ResourceFile, 0)
	paginator := s3.NewListObjectsV2Paginator(client, &s3.ListObjectsV2Input{
		Bucket:    aws.String(bucket),
		Prefix:    aws.String(prefix),
		Delimiter: aws.String("/"),
	})
	for paginator.HasMorePages() {
		page, err := paginator.NextPage(context.Background())
		if err != nil {
			return nil, err
		}
		for _, object := range page.Contents {
			fileName := aws.ToString(object.Key)[len(prefix):]
			if fileName == "" {
				continue
			}
			files = append(files, ResourceFile{
				FileName:     fileName,
				Size:         aws.ToInt64(object.Size),
				LastModified: aws.ToTime(object.LastModified),
			})
		}
	}
	return files, nil
}

// PresignResourceUpload は bucket の {charaID}/{fileName} に PUT するための署名付き URL を返す。
// ブラウザから S3 に直接アップロードする (Lambda を通すと 6MB を超えるファイルを送れないため)。
func (a *AWS) PresignResourceUpload(bucket string, charaID string, fileName string, contentType string, expires time.Duration) (string, error) {
	client, err := a.createS3Client()
	if err != nil {
		return "", err
	}

	presigner := s3.NewPresignClient(client)
	req, err := presigner.PresignPutObject(context.Background(), &s3.PutObjectInput{
		Bucket:      aws.String(bucket),
		Key:         aws.String(charaID + "/" + fileName),
		ContentType: aws.String(contentType),
	}, s3.WithPresignExpires(expires))
	if err != nil {
		return "", err
	}
	return req.URL, nil
}

// InvalidateResourceFiles は CloudFront のキャッシュから {charaID}/{fileName} を消す (同じ名前で上書きしたとき用)。
func (a *AWS) InvalidateResourceFiles(distributionID string, charaID string, fileNames []string) error {
	cfg, err := a.createAWSConfig()
	if err != nil {
		return err
	}
	client := cloudfront.NewFromConfig(cfg)

	paths := make([]string, 0, len(fileNames))
	for _, fileName := range fileNames {
		paths = append(paths, fmt.Sprintf("/%s/%s", charaID, fileName))
	}
	_, err = client.CreateInvalidation(context.Background(), &cloudfront.CreateInvalidationInput{
		DistributionId: aws.String(distributionID),
		InvalidationBatch: &cftypes.InvalidationBatch{
			CallerReference: aws.String(strconv.FormatInt(time.Now().UnixNano(), 10)),
			Paths: &cftypes.Paths{
				Quantity: aws.Int32(int32(len(paths))),
				Items:    paths,
			},
		},
	})
	return err
}
