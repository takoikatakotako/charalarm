FROM golang:1.27-alpine3.24 AS builder
WORKDIR /app
COPY . .
RUN go mod tidy
RUN CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -o main worker/main.go


FROM --platform=linux/arm64 alpine:3.24

WORKDIR /app
COPY --from=builder /app/main .

EXPOSE 8080

CMD ["/app/main"]
