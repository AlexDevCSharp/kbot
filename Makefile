
APP=$(shell basename $(shell git remote get-url origin))
REGESTRY=alexdevcsharp
VERSION=$(shell git describe --tags --abbrev=0)-$(shell git rev-parse --short HEAD)
TARGETOS=linux
TARGETARCH=amd64


format: 
	gofmt -s -w ./

get:
	go get

lint:
	golint

test: 
	go test -v

build: format get
	CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -v -o kbot -ldflags "-X="github.com/alexdevcsharp/kbot/cmd.appVersion=${VERSION}

image:
	docker build . -t ${REGESTRY}/${APP}:${VERSION}-${TARGETARCH}

push:
	docker push ${REGESTRY}/${APP}:${VERSION}-${TARGETARCH}

clean: 
	rm -rf kbot