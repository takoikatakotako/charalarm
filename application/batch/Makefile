REPOSITORY_URI = "448049807848.dkr.ecr.ap-northeast-1.amazonaws.com/charalarm/batch"
GITHUB_SHA ?= "local"

.PHONY: test
test:
		go test ./...

.PHONY: build-image
build-image:
	aws ecr get-login-password --region ap-northeast-1 --profile charalarm-management | docker login --username AWS --password-stdin 448049807848.dkr.ecr.ap-northeast-1.amazonaws.com
	docker build -t charalarm/batch .
	docker tag charalarm/batch:latest ${REPOSITORY_URI}:latest
	docker push ${REPOSITORY_URI}:latest
	docker tag charalarm/batch:latest ${REPOSITORY_URI}:${GITHUB_SHA}
	docker push ${REPOSITORY_URI}:${GITHUB_SHA}
