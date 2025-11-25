# Build stage
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY main.go .
RUN go build -o myapp main.go

# Final stage
FROM alpine:latest
WORKDIR /root/
COPY --from=builder /app/myapp .
EXPOSE 8080
CMD ["./myapp"]
