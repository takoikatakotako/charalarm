FROM golang:1.24.0-alpine3.21 AS builder
WORKDIR /app
COPY . .
RUN go mod tidy
RUN CGE_ENABLE=0 GOOS=linux GOARCH=arm64 go build -o main batch/main.go

FROM public.ecr.aws/lambda/provided:al2.2025.02.18.01
COPY --from=builder /app/main ./main
RUN chmod +x ./main
ENTRYPOINT ["./main" ]
