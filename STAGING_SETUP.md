# Staging Environment Setup Guide

**Purpose**: Configure staging environment for Shared-Kit testing  
**Target**: Pre-production validation  
**Date**: 2026-01-15

---

## Prerequisites

- macOS or Linux server
- Swift 5.9+ installed
- PostgreSQL 14+ (for vector store)
- Ollama running locally or remotely
- Git access to repositories

---

## 1. Environment Configuration

### Create Staging Directory

```bash
mkdir -p ~/staging/shared-kit
cd ~/staging/shared-kit
git clone https://github.com/dboone323/shared-kit.git .
git checkout main
```

### Environment Variables

Create `.env.staging`:

```bash
# Ollama Configuration
export OLLAMA_BASE_URL="http://localhost:11434"
export OLLAMA_TIMEOUT="60"
export OLLAMA_FALLBACK_MODELS="mistral,llama2,codellama"

# PostgreSQL Configuration
export POSTGRES_HOST="localhost"
export POSTGRES_PORT="5432"
export POSTGRES_USER="staging_user"
export POSTGRES_PASSWORD="<SECURE_PASSWORD>"
export POSTGRES_DB="shared_kit_staging"

# Logging
export LOG_LEVEL="debug"
export LOG_PATH="/var/log/shared-kit-staging"

# Feature Flags
export ENABLE_CACHING="true"
export ENABLE_HEALTH_TRACKING="true"
export ENABLE_CONNECTION_POOLING="true"
export ENABLE_RETRY_LOGIC="true"

# Performance
export MAX_CONCURRENT_REQUESTS="10"
export CACHE_TTL_SECONDS="300"
export MAX_RETRIES="3"
```

Load environment:

```bash
source .env.staging
```

---

## 2. Database Setup

### PostgreSQL Installation

```bash
# macOS
brew install postgresql@14
brew services start postgresql@14

# Linux
sudo apt-get install postgresql-14
sudo systemctl start postgresql
```

### Create Staging Database

```bash
createdb shared_kit_staging
psql shared_kit_staging << EOF
CREATE USER staging_user WITH PASSWORD '<SECURE_PASSWORD>';
GRANT ALL PRIVILEGES ON DATABASE shared_kit_staging TO staging_user;
EOF
```

### Run Migrations

```bash
# Apply vector store schema
psql shared_kit_staging < scripts/migrations/001_vector_store_init.sql
```

---

## 3. Ollama Setup

### Install Ollama

```bash
# macOS
brew install ollama

# Linux
curl https://ollama.ai/install.sh | sh
```

### Pull Models

```bash
ollama pull llama2
ollama pull mistral
ollama pull codellama
```

### Verify

```bash
curl http://localhost:11434/api/tags
```

---

## 4. Build & Test

### Build Shared-Kit

```bash
cd ~/staging/shared-kit
swift build -c release
```

### Run Tests

```bash
swift test
```

Expected: All tests passing ✅

---

## 5. Health Checks

### Create Health Check Script

Save as `scripts/staging_health_check.sh`:

```bash
#!/bin/bash

echo "🏥 Staging Health Check"
echo "======================="

# Check Ollama
if curl -s http://localhost:11434/api/tags > /dev/null; then
    echo "✅ Ollama: Running"
else
    echo "❌ Ollama: Not running"
fi

# Check PostgreSQL
if pg_isready -h localhost -p 5432 > /dev/null; then
    echo "✅ PostgreSQL: Running"
else
    echo "❌ PostgreSQL: Not running"
fi

# Check build
cd ~/staging/shared-kit
if swift build -c release 2>&1 | grep -q "Build complete"; then
    echo "✅ Build: Passing"
else
    echo "❌ Build: Failing"
fi

echo "======================="
```

Run health check:

```bash
bash scripts/staging_health_check.sh
```

---

## 6. Monitoring Setup

### Create Monitoring Script

Save as `scripts/monitor_staging.sh`:

```bash
#!/bin/bash

# Monitor staging performance
watch -n 5 '
echo "=== Staging Metrics ==="
echo "Ollama uptime: $(curl -s http://localhost:11434/api/tags | jq ".models | length") models"
echo "Postgres connections: $(psql -U staging_user -d shared_kit_staging -c "SELECT count(*) FROM pg_stat_activity" -t)"
echo "Disk usage: $(df -h ~/staging | tail -1 | awk "{print \$5}")"
echo "Memory: $(free -h | grep Mem | awk "{print \$3 \"/\" \$2}")"
'
```

---

## 7. Load Testing

### Install Apache Bench

```bash
brew install apache-bench  # macOS
sudo apt-get install apache2-utils  # Linux
```

### Run Load Test

```bash
# Test Ollama endpoint
ab -n 100 -c 10 http://localhost:11434/api/generate
```

---

## 8. Staging Workflow

### Deploy New Changes

```bash
cd ~/staging/shared-kit
git pull origin main
swift build -c release
swift test
bash scripts/staging_health_check.sh
```

### Simulate Production Load

```bash
# Run integration tests
swift test --filter IntegrationTests

# Run benchmarks
python3 scripts/benchmark_shared_kit.py

# Manual verification
# Test specific features
```

---

## 9. Rollback Procedure

### Save Current Version

```bash
cd ~/staging/shared-kit
git tag staging-$(date +%Y%m%d-%H%M%S)
git push origin --tags
```

### Rollback if Needed

```bash
# List versions
git tag | grep staging

# Rollback
git checkout staging-<timestamp>
swift build -c release
```

---

## 10. Staging Checklist

Before promoting to production:

- [ ] All tests passing
- [ ] Health checks green
- [ ] Load tests successful
- [ ] No memory leaks
- [ ] Performance acceptable
- [ ] Rollback tested
- [ ] Monitoring active
- [ ] Logs reviewed

---

## Troubleshooting

### Ollama Not Responding

```bash
# Restart Ollama
brew services restart ollama
# or
sudo systemctl restart ollama
```

### PostgreSQL Connection Issues

```bash
# Check logs
tail -f /usr/local/var/log/postgresql@14.log

# Restart
brew services restart postgresql@14
```

### Build Failures

```bash
# Clean build
swift package clean
swift build -c release
```

---

## Next Steps

1. Complete staging validation
2. Update CI/CD pipeline (Step 24)
3. Set up production monitoring (Step 25)
4. Prepare production deployment

---

**Status**: Step 21 ✅ Complete  
**Next**: Database migrations (Step 22)
