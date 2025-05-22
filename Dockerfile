FROM quay.io/projectquay/golang:1.21 AS test
WORKDIR /app
COPY . .
RUN go test -v ./...

FROM quay.io/projectquay/golang:1.21 AS builder
WORKDIR /go/src/app
COPY . .
RUN make build

FROM scratch
WORKDIR /
COPY --from=builder /go/src/app/kbot .
COPY --from=alpine:latest /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
ENTRYPOINT ["./kbot"]
