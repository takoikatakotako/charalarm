FROM golang:1.23.2-alpine3.19 AS builder
WORKDIR /app
COPY .. .
RUN go mod tidy
RUN CGE_ENABLE=0 GOOS=linux GOARCH=arm64 go build -o main api/main.go


FROM golang:1.23.2-alpine3.19

WORKDIR /app
COPY --from=builder /app/main .

COPY --from=public.ecr.aws/awsguru/aws-lambda-adapter:0.9.0 /lambda-adapter /opt/extensions/lambda-adapter

EXPOSE 8080

CMD ["/app/main"]
