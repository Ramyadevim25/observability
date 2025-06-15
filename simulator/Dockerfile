FROM golang:1.20-alpine

WORKDIR /app

COPY log_simulator.go .

RUN go build -o log_simulator log_simulator.go

CMD ["./log_simulator"]
