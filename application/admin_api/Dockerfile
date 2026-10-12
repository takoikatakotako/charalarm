FROM golang:1.27-alpine3.24 AS builder
WORKDIR /app
COPY . .
RUN go mod tidy
RUN CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -o main admin_api/main.go


FROM alpine:3.24

WORKDIR /app
COPY --from=builder /app/main .

COPY --from=public.ecr.aws/awsguru/aws-lambda-adapter:1.1.0 /lambda-adapter /opt/extensions/lambda-adapter

EXPOSE 8080

CMD ["/app/main"]
