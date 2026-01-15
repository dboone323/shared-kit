# Shared-Kit Monitoring Guide

**Purpose**: Prometheus & Grafana monitoring configuration  
**Target**: Production  
**Date**: 2026-01-15

---

## Overview

Shared-Kit exposes metrics for:

- **Ollama Client**: Request rates, latency, errors, token counts
- **Vector Store**: Query performance, cache hit rates
- **Agents**: Task completion rates, tool usage, health status
- **System**: Memory usage, active tasks

---

## 1. Metrics Endpoint

Shared-Kit can expose a `/metrics` endpoint compatible with Prometheus.

### Configuration

Enable in `ENVIRONMENT_VARIABLES.md`:

```bash
ENABLE_METRICS="true"
METRICS_PORT="9090"
```

### Metrics Format (Prometheus)

```text
# HELP ollama_requests_total Total number of Ollama API requests
# TYPE ollama_requests_total counter
ollama_requests_total{model="llama2",status="success"} 1042
ollama_requests_total{model="llama2",status="error"} 5

# HELP ollama_latency_seconds Request latency in seconds
# TYPE ollama_latency_seconds histogram
ollama_latency_seconds_bucket{le="0.1"} 50
ollama_latency_seconds_bucket{le="0.5"} 150
ollama_latency_seconds_bucket{le="1.0"} 200

# HELP vector_search_duration_seconds Vector search duration
# TYPE vector_search_duration_seconds histogram
vector_search_duration_seconds_sum 12.5
vector_search_duration_seconds_count 100

# HELP agent_health_score Agent health score (0-1)
# TYPE agent_health_score gauge
agent_health_score{agent="debugging"} 1.0
agent_health_score{agent="securing"} 0.95
```

---

## 2. Prometheus Configuration

Save as `monitoring/prometheus.yml`:

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: "shared-kit"
    static_configs:
      - targets: ["localhost:9090"]
    metrics_path: "/metrics"
    scheme: "http"

  - job_name: "ollama"
    static_configs:
      - targets: ["localhost:11434"]
    # If Ollama exposes metrics manually

  - job_name: "postgres"
    static_configs:
      - targets: ["localhost:9187"] # Postgres Exporter
```

---

## 3. Grafana Dashboard

### Dashboard JSON Structure

Typically you would import a JSON dashboard. Key panels:

1.  **System Health**

    - Stat: Overall Health Score (Avg of all agents)
    - Gauge: Active Agents (Count)

2.  **LLM Performance**

    - Graph: Requests/sec per Model
    - Graph: Average Latency (P95)
    - Graph: Error Rate (%)

3.  **Vector Store**

    - Graph: Queries/sec
    - Stat: Cache Hit Rate (%)
    - Heatmap: Query Latency Distribution

4.  **Agent Activity**
    - Table: Recent Tasks
    - Bar Gauge: Tool Usage Frequency

---

## 4. Alerts (Prometheus Rules)

Save as `monitoring/alerts.yml`:

```yaml
groups:
  - name: shared-kit-alerts
    rules:
      - alert: HighErrorRate
        expr: rate(ollama_requests_total{status="error"}[5m]) / rate(ollama_requests_total[5m]) > 0.1
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High LLM Error Rate"
          description: "Error rate is above 10% for last 5 minutes"

      - alert: AgentUnhealthy
        expr: agent_health_score < 0.5
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Agent Unhealthy"
          description: "Agent {{ $labels.agent }} health score dropped below 50%"

      - alert: HighLatency
        expr: histogram_quantile(0.95, rate(ollama_latency_seconds_bucket[5m])) > 5.0
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High LLM Latency"
          description: "P95 latency is above 5 seconds"
```

---

## 5. Setup Script

We provide a script to generate these configurations locally.

```bash
bash scripts/setup_monitoring.sh
```

---

**Status**: Monitoring Design Complete  
**Next**: Run setup script
