API_REPOSITORY_URI = 448049807848.dkr.ecr.ap-northeast-1.amazonaws.com/charalarm-api
BATCH_REPOSITORY_URI = 448049807848.dkr.ecr.ap-northeast-1.amazonaws.com/charalarm-batch
WORKER_REPOSITORY_URI = 448049807848.dkr.ecr.ap-northeast-1.amazonaws.com/charalarm-worker

GITHUB_SHA ?= local

.PHONY: test
test:
		go clean -testcache
		go test ./...


# API
.PHONY: build-api-image
build-api-image:
	aws ecr get-login-password --region ap-northeast-1 --profile charalarm-management | docker login --username AWS --password-stdin 448049807848.dkr.ecr.ap-northeast-1.amazonaws.com
	docker buildx create --use --platform linux/arm64
	docker buildx build --platform linux/arm64 -t charalarm/api:latest --load -f api/Dockerfile .
	docker tag charalarm/api:latest ${API_REPOSITORY_URI}:latest
	docker push ${API_REPOSITORY_URI}:latest
	docker tag charalarm/api:latest ${API_REPOSITORY_URI}:${GITHUB_SHA}
	docker push ${API_REPOSITORY_URI}:${GITHUB_SHA}

.PHONY: list-api-images
list-api-imagess:
	aws ecr list-images --repository-name charalarm-api --output table --profile charalarm-management


# Batch
.PHONY: build-batch-image
build-batch-image:
	aws ecr get-login-password --region ap-northeast-1 --profile charalarm-management | docker login --username AWS --password-stdin 448049807848.dkr.ecr.ap-northeast-1.amazonaws.com
	docker buildx create --use --platform linux/arm64
	docker buildx build --platform linux/arm64 -t charalarm/batch:latest --load -f batch/Dockerfile .
	docker tag charalarm/batch:latest ${BATCH_REPOSITORY_URI}:latest
	docker push ${BATCH_REPOSITORY_URI}:latest
	docker tag charalarm/batch:latest ${BATCH_REPOSITORY_URI}:${GITHUB_SHA}
	docker push ${BATCH_REPOSITORY_URI}:${GITHUB_SHA}

.PHONY: list-batch-images
list-batch-imagess:
	aws ecr list-images --repository-name charalarm-batch --output table --profile charalarm-management


# Worker
.PHONY: build-worker-image
build-worker-image:
	aws ecr get-login-password --region ap-northeast-1 --profile charalarm-management | docker login --username AWS --password-stdin 448049807848.dkr.ecr.ap-northeast-1.amazonaws.com
	docker buildx create --use --platform linux/arm64
	docker buildx build --platform linux/arm64 -t charalarm/worker:latest --load -f worker/Dockerfile .
	docker tag charalarm/worker:latest ${WORKER_REPOSITORY_URI}:latest
	docker push ${WORKER_REPOSITORY_URI}:latest
	docker tag charalarm/worker:latest ${WORKER_REPOSITORY_URI}:${GITHUB_SHA}
	docker push ${WORKER_REPOSITORY_URI}:${GITHUB_SHA}

.PHONY: list-worker-images
list-worker-images:
	aws ecr list-images --repository-name charalarm-worker --output table --profile charalarm-management

