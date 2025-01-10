#!/bin/bash

set -eu

cwd=`dirname $0`
cd $cwd/../application

pwd

################################################################
# Build
################################################################
# alarm
CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -o build/alarm_add/bootstrap handler/alarm_add/alarm_add.go
CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -o build/alarm_edit/bootstrap handler/alarm_edit/alarm_edit.go
CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -o build/alarm_delete/bootstrap handler/alarm_delete/alarm_delete.go
CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -o build/alarm_list/bootstrap handler/alarm_list/alarm_list.go

# call_batch
CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -o build/batch/bootstrap handler/call_batch/call_batch.go

# chara
CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -o build/chara_id/bootstrap handler/chara_id/chara_id.go
CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -o build/chara_list/bootstrap handler/chara_list/chara_list.go

# maintenance
CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -o build/maintenance/bootstrap handler/maintenance/maintenance.go

# healthcheck
CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -o build/healthcheck/bootstrap handler/healthcheck/healthcheck.go

# push-token
CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -o build/push_token_ios_push_add/bootstrap handler/push_token_ios_push_add/push_token_ios_push_add.go
CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -o build/push_token_ios_voip_push_add/bootstrap handler/push_token_ios_voip_push_add/push_token_ios_voip_push_add.go

# require
CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -o build/require/bootstrap handler/require/require.go

# user
CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -o build/user_info/bootstrap handler/user_info/user_info.go
CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -o build/user_signup/bootstrap handler/user_signup/user_signup.go
CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -o build/user_withdraw/bootstrap handler/user_withdraw/user_withdraw.go
CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -o build/user_update_premium/bootstrap handler/user_update_premium/user_update_premium.go

# call_worker
CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -o build/worker/bootstrap handler/call_worker/call_worker.go


################################################################
# Archive
################################################################
cd ./build

# alarm
zip -j alarm_add.zip alarm_add/bootstrap
zip -j alarm_delete.zip alarm_delete/bootstrap
zip -j alarm_edit.zip alarm_edit/bootstrap
zip -j alarm_list.zip alarm_list/bootstrap

# call_batch
zip -j batch.zip batch/bootstrap

# chara
zip -j chara_id.zip chara_id/bootstrap
zip -j chara_list.zip chara_list/bootstrap

# maintenance
zip -j maintenance.zip maintenance/bootstrap

# healthcheck
zip -j healthcheck.zip healthcheck/bootstrap

# push-notification
zip -j push_token_ios_push_add.zip push_token_ios_push_add/bootstrap
zip -j push_token_ios_voip_push_add.zip push_token_ios_voip_push_add/bootstrap

# require
zip -j require.zip require/bootstrap

# user
zip -j user_signup.zip user_signup/bootstrap
zip -j user_info.zip user_info/bootstrap
zip -j user_withdraw.zip user_withdraw/bootstrap
zip -j user_update_premium.zip user_update_premium/bootstrap

# call_worker
zip -j worker.zip worker/bootstrap

################################################################
# Clear
################################################################
ls | grep -v -E '.zip$' | xargs rm -r



################################################################
# Upload
################################################################
aws s3 sync . s3://$S3_BUCKET_NAME/$APPLICATION_VERSION --exact-timestamps --delete



################################################################
# Deploy
################################################################

# alarm
aws lambda update-function-code --function-name alarm-add-post-function --s3-bucket $S3_BUCKET_NAME --s3-key $APPLICATION_VERSION/alarm_add.zip
aws lambda update-function-code --function-name alarm-delete-post-function --s3-bucket $S3_BUCKET_NAME --s3-key $APPLICATION_VERSION/alarm_delete.zip
aws lambda update-function-code --function-name alarm-edit-post-function --s3-bucket $S3_BUCKET_NAME --s3-key $APPLICATION_VERSION/alarm_edit.zip
aws lambda update-function-code --function-name alarm-list-post-function --s3-bucket $S3_BUCKET_NAME --s3-key $APPLICATION_VERSION/alarm_list.zip

# call_batch
aws lambda update-function-code --function-name batch-function --s3-bucket $S3_BUCKET_NAME --s3-key $APPLICATION_VERSION/batch.zip

# chara
aws lambda update-function-code --function-name chara-id-get-function --s3-bucket $S3_BUCKET_NAME --s3-key $APPLICATION_VERSION/chara_id.zip
aws lambda update-function-code --function-name chara-list-get-function --s3-bucket $S3_BUCKET_NAME --s3-key $APPLICATION_VERSION/chara_list.zip

# maintenance
aws lambda update-function-code --function-name maintenance-get-function --s3-bucket $S3_BUCKET_NAME --s3-key $APPLICATION_VERSION/maintenance.zip

# healthcheck
aws lambda update-function-code --function-name healthcheck-get-function --s3-bucket $S3_BUCKET_NAME --s3-key $APPLICATION_VERSION/healthcheck.zip

# push-notification
aws lambda update-function-code --function-name push-token-ios-push-add-post-function --s3-bucket $S3_BUCKET_NAME --s3-key $APPLICATION_VERSION/push_token_ios_push_add.zip
aws lambda update-function-code --function-name push-token-ios-voip-push-add-post-function --s3-bucket $S3_BUCKET_NAME --s3-key $APPLICATION_VERSION/push_token_ios_voip_push_add.zip

# require
aws lambda update-function-code --function-name require-get-function --s3-bucket $S3_BUCKET_NAME --s3-key $APPLICATION_VERSION/require.zip

# user
aws lambda update-function-code --function-name user-signup-post-function --s3-bucket $S3_BUCKET_NAME --s3-key $APPLICATION_VERSION/user_signup.zip
aws lambda update-function-code --function-name user-withdraw-post-function --s3-bucket $S3_BUCKET_NAME --s3-key $APPLICATION_VERSION/user_withdraw.zip
aws lambda update-function-code --function-name user-info-post-function --s3-bucket $S3_BUCKET_NAME --s3-key $APPLICATION_VERSION/user_info.zip
aws lambda update-function-code --function-name user-update-premium-post-function --s3-bucket $S3_BUCKET_NAME --s3-key $APPLICATION_VERSION/user_update_premium.zip

# call_worker
aws lambda update-function-code --function-name worker-function --s3-bucket $S3_BUCKET_NAME --s3-key $APPLICATION_VERSION/worker.zip
