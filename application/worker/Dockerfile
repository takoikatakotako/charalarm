FROM golang:1.23.2-alpine3.19 AS builder
WORKDIR /app
COPY . .
RUN go mod tidy
RUN CGE_ENABLE=0 GOOS=linux GOARCH=arm64 go build -o main main.go


FROM --platform=linux/arm64 golang:1.23.2-alpine3.19

WORKDIR /app
COPY --from=builder /app/main .

EXPOSE 8080

CMD ["/app/main"]
