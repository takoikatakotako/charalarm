API_REPOSITORY_URI = 448049807848.dkr.ecr.ap-northeast-1.amazonaws.com/charalarm-api
ADMIN_API_REPOSITORY_URI = 448049807848.dkr.ecr.ap-northeast-1.amazonaws.com/charalarm-admin-api
BATCH_REPOSITORY_URI = 448049807848.dkr.ecr.ap-northeast-1.amazonaws.com/charalarm-batch
WORKER_REPOSITORY_URI = 448049807848.dkr.ecr.ap-northeast-1.amazonaws.com/charalarm-worker

GITHUB_SHA ?= local

.PHONY: test
test:
		go clean -testcache
		go test -p 1 ./...


# API
.PHONY: build-api-image
build-api-image:
	aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin 448049807848.dkr.ecr.ap-northeast-1.amazonaws.com
	docker buildx build --platform linux/arm64 \
		-t ${API_REPOSITORY_URI}:latest \
		-t ${API_REPOSITORY_URI}:${GITHUB_SHA} \
		--provenance=false --push -f api/Dockerfile .

.PHONY: list-api-images
list-api-images:
	aws ecr list-images --registry-id 448049807848 --repository-name charalarm-api --output table


# Admin API
.PHONY: build-admin-api-image
build-admin-api-image:
	aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin 448049807848.dkr.ecr.ap-northeast-1.amazonaws.com
	docker buildx build --platform linux/arm64 \
		-t ${ADMIN_API_REPOSITORY_URI}:latest \
		-t ${ADMIN_API_REPOSITORY_URI}:${GITHUB_SHA} \
		--provenance=false --push -f admin_api/Dockerfile .

.PHONY: list-admin-api-images
list-admin-api-images:
	aws ecr list-images --registry-id 448049807848 --repository-name charalarm-admin-api --output table


# Batch
.PHONY: build-batch-image
build-batch-image:
	aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin 448049807848.dkr.ecr.ap-northeast-1.amazonaws.com
	docker buildx build --platform linux/arm64 \
		-t ${BATCH_REPOSITORY_URI}:latest \
		-t ${BATCH_REPOSITORY_URI}:${GITHUB_SHA} \
		--provenance=false --push -f batch/Dockerfile .

.PHONY: list-batch-images
list-batch-images:
	aws ecr list-images --registry-id 448049807848 --repository-name charalarm-batch --output table


# Worker
.PHONY: build-worker-image
build-worker-image:
	aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin 448049807848.dkr.ecr.ap-northeast-1.amazonaws.com
	docker buildx build --platform linux/arm64 \
		-t ${WORKER_REPOSITORY_URI}:latest \
		-t ${WORKER_REPOSITORY_URI}:${GITHUB_SHA} \
		--provenance=false --push -f worker/Dockerfile .

.PHONY: list-worker-images
list-worker-images:
	aws ecr list-images --registry-id 448049807848 --repository-name charalarm-worker --output table
