package trendnews

import "github.com/takoikatakotako/charalarm/infrastructure"

// S3Publisher は resource のバケットに JSON を置く。CloudFront で配る。
type S3Publisher struct {
	AWS    infrastructure.AWS
	Bucket string
}

// Publish は key にファイルを置く。
func (p S3Publisher) Publish(key string, contentType string, cacheControl string, data []byte) error {
	return p.AWS.PutPublicFile(p.Bucket, key, contentType, cacheControl, data)
}
