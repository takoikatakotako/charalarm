REPOSITORY_URI = "448049807848.dkr.ecr.ap-northeast-1.amazonaws.com/charalarm/api"
GITHUB_SHA ?= "local"

.PHONY: test
test:
		go test ./...


.PHONY: build-image
build-image:
	aws ecr get-login-password --region ap-northeast-1 --profile charalarm-management | docker login --username AWS --password-stdin 448049807848.dkr.ecr.ap-northeast-1.amazonaws.com
	docker buildx create --use --platform linux/arm64
	docker buildx build --platform linux/arm64 -t charalarm/api:latest --load .
	docker tag charalarm/api:latest ${REPOSITORY_URI}:latest
	docker push ${REPOSITORY_URI}:latest
	docker tag charalarm/api:latest ${REPOSITORY_URI}:${GITHUB_SHA}
	docker push ${REPOSITORY_URI}:${GITHUB_SHA}



