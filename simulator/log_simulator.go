package main

import (
	"bytes"
	"encoding/json"
	"io/ioutil"
	"math/rand"
	"os"
	"path/filepath"
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
	outputFile := "infra_output.json"
	data, err := ioutil.ReadFile(outputFile)
	if err != nil {
		os.Exit(1)
	}

	data = bytes.TrimPrefix(data, []byte{0xEF, 0xBB, 0xBF})

	var tfOutput TerraformOutput
	if err := json.Unmarshal(data, &tfOutput); err != nil {
		os.Exit(1)
	}

	for _, svc := range tfOutput.Services.Value {
		go writeLogs(svc.Name, svc.Environment)
	}

	select {} // keep goroutines alive
}

func writeLogs(service, environment string) {
	logDir := "logs"
	_ = os.MkdirAll(logDir, os.ModePerm)

	filePath := filepath.Join(logDir, service+".log")
	rand.Seed(time.Now().UnixNano())

	for {
		f, err := os.OpenFile(filePath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
		if err != nil {
			continue
		}

		// Random log level
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
			Message:     "Simulated " + level + " log for " + service + " service",
			Component:   "core",
			Environment: environment,
		}

		entryJSON, _ := json.Marshal(entry)
		f.WriteString(string(entryJSON) + "\n")
		f.Close()

		time.Sleep(5 * time.Second)
	}
}
