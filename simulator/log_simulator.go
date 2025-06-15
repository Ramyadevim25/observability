package main

import (
    "bytes"
    "encoding/json"
    "fmt"
    "io/ioutil"
    "math/rand"
    "os"
    "time"
)

type TerraformOutput struct {
    LogGroupNames struct {
        Value []string `json:"value"`
    } `json:"log_group_names"`
    Services struct {
        Value []struct {
            Name        string `json:"name"`
            Environment string `json:"environment"`
        } `json:"value"`
    } `json:"services"`
}

type LogEntry struct {
    Service     string `json:"service"`
    Timestamp   string `json:"timestamp"`
    Level       string `json:"level"`
    Message     string `json:"message"`
    Component   string `json:"component"`
    Environment string `json:"environment"`
}

func main() {
    outputFile := "C:/Users/HP/Downloads/Observability_project/simulator/infra_output.json"

    data, err := ioutil.ReadFile(outputFile)
    if err != nil {
        fmt.Printf("Error reading Terraform output: %v\n", err)
        os.Exit(1)
    }

    data = bytes.TrimPrefix(data, []byte{0xEF, 0xBB, 0xBF})

    var tfOutput TerraformOutput
    if err := json.Unmarshal(data, &tfOutput); err != nil {
        fmt.Printf("Error parsing Terraform output JSON: %v\n", err)
        os.Exit(1)
    }

    fmt.Printf("Parsed services: %+v\n", tfOutput.Services.Value)

    for _, svc := range tfOutput.Services.Value {
        go writeLogs(svc.Name, svc.Environment)
    }

    select {}
}

func writeLogs(service string, environment string) {
    logDir := "C:/Users/HP/Downloads/Observability_project/simulator/logs"
    err := os.MkdirAll(logDir, os.ModePerm)
    if err != nil {
        fmt.Printf("Error creating log directory: %v\n", err)
        return
    }

    filePath := fmt.Sprintf("%s/%s.log", logDir, service)
    f, err := os.OpenFile(filePath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
    if err != nil {
        fmt.Printf("Error opening log file: %v\n", err)
        return
    }
    defer f.Close()

    rand.Seed(time.Now().UnixNano())

    for {
        var level string
        n := rand.Intn(100)
        switch {
        case n < 10:
            level = "ERROR"
        case n < 30:
            level = "WARNING"
        default:
            level = "INFO"
        }

        entry := LogEntry{
            Service:     service,
            Timestamp:   time.Now().UTC().Format(time.RFC3339),
            Level:       level,
            Message:     fmt.Sprintf("Simulated %s log for %s service", level, service),
            Component:   "core",
            Environment: environment,
        }

        entryJSON, _ := json.Marshal(entry)
        f.WriteString(string(entryJSON) + "\n")

        time.Sleep(5 * time.Second)
    }
}
