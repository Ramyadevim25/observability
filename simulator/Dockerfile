# simulator/Dockerfile

FROM golang:1.21

WORKDIR /app

COPY log_simulator.go .
COPY infra_output.json .  # Terraform output for services

RUN go build -o log_simulator log_simulator.go

CMD ["./log_simulator"]
