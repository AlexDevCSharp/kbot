APP := $(shell basename $(shell git rev-parse --show-toplevel))
NAMESPACE := alexdevcsharp
REGISTRY = quay.io/${NAMESPACE}
VERSION := $(shell git describe --tags --abbrev=0)-$(shell git rev-parse --short HEAD)

TARGETOS ?= linux
TARGETARCH ?= amd64
PLATFORM ?= ${TARGETOS}/${TARGETARCH}
IMAGE_TAG := ${REGISTRY}/${APP}:${VERSION}-${TARGETARCH}

PLATFORMS := linux/amd64 linux/arm64 windows/amd64 darwin/amd64 darwin/arm64

.PHONY: all format get lint test build clean \
        linux arm macos windows docker-build docker-push docker-test

format:
	gofmt -s -w ./

get:
	go get

lint:
	golint

test:
	go test -v ./...

build: format get
	CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -v -o kbot -ldflags "-X=github.com/alexdevcsharp/kbot/cmd.appVersion=${VERSION}"

linux:
	docker buildx build \
		--platform linux/amd64 \
		--output type=docker \
		--tag ${REGISTRY}/${APP}:linux-amd64 .

arm:
	docker buildx build \
		--platform linux/arm64 \
		--output type=docker \
		--tag ${REGISTRY}/${APP}:linux-arm64 .

macos:
	docker buildx build \
		--platform darwin/amd64,darwin/arm64 \
		--output type=docker \
		--tag ${REGISTRY}/${APP}:macos .

windows:
	docker buildx build \
		--platform windows/amd64 \
		--output type=docker \
		--tag ${REGISTRY}/${APP}:windows-amd64 .

docker-build:
	docker buildx build \
		--platform ${PLATFORMS} \
		--tag ${REGISTRY}/${APP}:multi \
		--push .

docker-push:
	docker push ${REGISTRY}/${APP}:multi


docker-test-linux-arm:
	docker buildx build \
		--target test \
		--platform linux/arm64 \
		--tag ${REGISTRY}/${APP}:test-linux-arm64 \
		--load .
	docker run --rm ${REGISTRY}/${APP}:test-linux-arm64

docker-test-windows:
	docker buildx build \
		--target test \
		--platform windows/amd64 \
		--tag ${REGISTRY}/${APP}:test-windows-amd64 \
		--load .
	docker run --rm ${REGISTRY}/${APP}:test-windows-amd64

clean:
	rm -f kbot
	-docker rmi ${IMAGE_TAG} || true
	-docker rmi ${REGISTRY}/${APP}:linux-amd64 || true
	-docker rmi ${REGISTRY}/${APP}:linux-arm64 || true
	-docker rmi ${REGISTRY}/${APP}:macos || true
	-docker rmi ${REGISTRY}/${APP}:windows-amd64 || true
	-docker rmi ${REGISTRY}/${APP}:multi || true
	-docker rmi ${REGISTRY}/${APP}:test-linux-arm64 || true
	-docker rmi ${REGISTRY}/${APP}:test-windows-amd64 || true