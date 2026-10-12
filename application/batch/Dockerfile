FROM golang:1.27-alpine3.24 AS builder
WORKDIR /app
COPY . .
RUN go mod tidy
RUN CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -o main batch/main.go

FROM public.ecr.aws/lambda/provided:al2.2025.02.18.01
COPY --from=builder /app/main ./main
RUN chmod +x ./main
ENTRYPOINT ["./main" ]
