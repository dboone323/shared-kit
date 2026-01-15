# Environment Variables - Shared-Kit

**Purpose**: Complete reference for all environment variables  
**Target**: Development, Staging, and Production  
**Date**: 2026-01-15

---

## Ollama Configuration

### Required

```bash
# Base URL for Ollama API
OLLAMA_BASE_URL="http://localhost:11434"
```

### Optional

```bash
# Request timeout in seconds (default: 60)
OLLAMA_TIMEOUT="60"

# Fallback models (comma-separated)
OLLAMA_FALLBACK_MODELS="mistral,llama2,codellama"

# Max concurrent requests (default: 10)
MAX_CONCURRENT_OLLAMA_REQUESTS="10"
```

---

## PostgreSQL Configuration

### Required

```bash
POSTGRES_HOST="localhost"
POSTGRES_PORT="5432"
POSTGRES_USER="your_user"
POSTGRES_PASSWORD="<SECURE_PASSWORD>"
POSTGRES_DB="shared_kit"
```

### Optional

```bash
# Connection pool size (default: 10)
POSTGRES_POOL_SIZE="10"

# Connection timeout in seconds (default: 30)
POSTGRES_TIMEOUT="30"
```

---

## Feature Flags

```bash
# Enable/disable enhancements
ENABLE_CACHING="true"              # Tool result caching
ENABLE_HEALTH_TRACKING="true"      # Model health tracking
ENABLE_CONNECTION_POOLING="true"   # Connection reuse
ENABLE_RETRY_LOGIC="true"          # Automatic retries
ENABLE_PARALLEL_EXECUTION="true"   # Parallel tool execution
ENABLE_LEARNING_SYSTEM="true"      # Tool learning & recommendations
```

---

## Performance Tuning

```bash
# Cache settings
CACHE_TTL_SECONDS="300"           # 5 minutes
MAX_CACHE_SIZE="1000"             # Max cached items

# Retry settings
MAX_RETRIES="3"
RETRY_BASE_DELAY="1.0"            # Seconds
RETRY_MAX_DELAY="30.0"            # Seconds
RETRY_JITTER="true"

# Context window
MAX_CONTEXT_TOKENS="4096"
TOKENS_PER_MESSAGE_ESTIMATE="100"

# Request queue
MAX_QUEUE_SIZE="100"
QUEUE_TIMEOUT="300"               # 5 minutes
```

---

## Logging

```bash
# Log level: debug, info, notice, error
LOG_LEVEL="info"

# Log output path (optional, defaults to system logger)
LOG_PATH="/var/log/shared-kit"

# Log rotation
LOG_MAX_SIZE_MB="100"
LOG_MAX_FILES="10"
```

---

## Monitoring

```bash
# Enable metrics collection
ENABLE_METRICS="true"

# Metrics export interval (seconds)
METRICS_INTERVAL="60"

# Prometheus endpoint (optional)
PROMETHEUS_ENDPOINT="http://localhost:9090"
```

---

## Environment-Specific Examples

### Development (.env.development)

```bash
# Ollama
OLLAMA_BASE_URL="http://localhost:11434"
OLLAMA_TIMEOUT="60"

# PostgreSQL
POSTGRES_HOST="localhost"
POSTGRES_PORT="5432"
POSTGRES_USER="dev_user"
POSTGRES_PASSWORD="dev_password"
POSTGRES_DB="shared_kit_dev"

# Features - All enabled for testing
ENABLE_CACHING="true"
ENABLE_HEALTH_TRACKING="true"
ENABLE_CONNECTION_POOLING="true"
ENABLE_RETRY_LOGIC="true"

# Logging
LOG_LEVEL="debug"

# Performance - Relaxed for dev
MAX_RETRIES="2"
CACHE_TTL_SECONDS="60"
```

### Staging (.env.staging)

```bash
# Ollama
OLLAMA_BASE_URL="http://staging-ollama:11434"
OLLAMA_TIMEOUT="60"
OLLAMA_FALLBACK_MODELS="mistral,llama2"

# PostgreSQL
POSTGRES_HOST="staging-db"
POSTGRES_PORT="5432"
POSTGRES_USER="staging_user"
POSTGRES_PASSWORD="<SECURE_STAGING_PASSWORD>"
POSTGRES_DB="shared_kit_staging"

# Features - All enabled
ENABLE_CACHING="true"
ENABLE_HEALTH_TRACKING="true"
ENABLE_CONNECTION_POOLING="true"
ENABLE_RETRY_LOGIC="true"
ENABLE_PARALLEL_EXECUTION="true"
ENABLE_LEARNING_SYSTEM="true"

# Logging
LOG_LEVEL="info"
LOG_PATH="/var/log/shared-kit-staging"

# Performance - Production-like
MAX_RETRIES="3"
CACHE_TTL_SECONDS="300"
MAX_CONCURRENT_REQUESTS="10"

# Monitoring
ENABLE_METRICS="true"
METRICS_INTERVAL="60"
```

### Production (.env.production)

```bash
# Ollama
OLLAMA_BASE_URL="https://ollama.production.internal:11434"
OLLAMA_TIMEOUT="90"
OLLAMA_FALLBACK_MODELS="mistral,llama2,codellama"

# PostgreSQL
POSTGRES_HOST="prod-db.internal"
POSTGRES_PORT="5432"
POSTGRES_USER="prod_user"
POSTGRES_PASSWORD="<SECURE_PROD_PASSWORD>"  # Use secrets manager
POSTGRES_DB="shared_kit_prod"
POSTGRES_POOL_SIZE="20"

# Features - Selective
ENABLE_CACHING="true"
ENABLE_HEALTH_TRACKING="true"
ENABLE_CONNECTION_POOLING="true"
ENABLE_RETRY_LOGIC="true"
ENABLE_PARALLEL_EXECUTION="true"
ENABLE_LEARNING_SYSTEM="false"  # Disable in prod until validated

# Logging
LOG_LEVEL="notice"
LOG_PATH="/var/log/shared-kit"
LOG_MAX_SIZE_MB="500"
LOG_MAX_FILES="30"

# Performance - Optimized
MAX_RETRIES="5"
RETRY_MAX_DELAY="60.0"
CACHE_TTL_SECONDS="600"  # 10 minutes
MAX_CACHE_SIZE="5000"
MAX_CONCURRENT_REQUESTS="50"

# Monitoring
ENABLE_METRICS="true"
METRICS_INTERVAL="30"
PROMETHEUS_ENDPOINT="https://prometheus.prod.internal"
```

---

## Security Best Practices

### Never Commit Secrets

- Use `.gitignore` for `.env*` files
- Use environment-specific files
- Rotate passwords regularly

### Use Secrets Management

```bash
# Production example with AWS Secrets Manager
POSTGRES_PASSWORD=$(aws secretsmanager get-secret-value \
    --secret-id prod/shared-kit/postgres \
    --query SecretString \
    --output text)
```

### Template File

Create `.env.template` for documentation:

```bash
# Ollama
OLLAMA_BASE_URL="http://localhost:11434"
OLLAMA_TIMEOUT="60"

# PostgreSQL
POSTGRES_HOST="localhost"
POSTGRES_PORT="5432"
POSTGRES_USER="your_user"
POSTGRES_PASSWORD="<CHANGE_ME>"
POSTGRES_DB="shared_kit"

# Features
ENABLE_CACHING="true"
ENABLE_HEALTH_TRACKING="true"

# ... etc
```

---

## Loading Environment

### Shell Script

```bash
#!/bin/bash
ENV=${1:-development}
if [ -f ".env.$ENV" ]; then
    export $(cat ".env.$ENV" | xargs)
    echo "✅ Loaded .env.$ENV"
else
    echo "❌ File not found: .env.$ENV"
    exit 1
fi
```

### Swift Package

```swift
import Foundation

extension ProcessInfo {
    var ollamaBaseURL: String {
        processInfo.environment["OLLAMA_BASE_URL"] ?? "http://localhost:11434"
    }

    var enableCaching: Bool {
        processInfo.environment["ENABLE_CACHING"] == "true"
    }

    // ... etc
}
```

---

## Validation

### Check Required Variables

```bash
#!/bin/bash
required_vars=(
    "OLLAMA_BASE_URL"
    "POSTGRES_HOST"
    "POSTGRES_USER"
    "POSTGRES_PASSWORD"
    "POSTGRES_DB"
)

for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "❌ Missing required variable: $var"
        exit 1
    fi
done

echo "✅ All required variables set"
```

---

**Status**: Step 23 ✅ Complete  
**Next**: CI/CD pipeline (Step 24)
