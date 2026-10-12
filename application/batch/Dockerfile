FROM golang:1.27-alpine3.24 AS builder
WORKDIR /app
COPY . .
RUN go mod tidy
RUN CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -o main batch/main.go

# aws-lambda-go が Lambda のランタイム API を自分で話すので、OS は何でもよい。
# Amazon Linux 2（2026-06-30 にサポート終了）をやめ、worker と同じ alpine にそろえる。
FROM --platform=linux/arm64 alpine:3.24

WORKDIR /app
COPY --from=builder /app/main .

CMD ["/app/main"]
