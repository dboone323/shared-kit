# Shared-Kit Deployment Guide

**Target**: Production  
**Date**: 2026-01-15  
**Version**: 1.0

---

## 1. Prerequisites

- **Server**: 2x vCPU, 4GB RAM minimum
- **OS**: Ubuntu 22.04 LTS or macOS 14+
- **Deps**: Swift 5.9+, PostgreSQL 14+, Ollama
- **Network**: Ports 8080 (API), 11434 (Ollama), 5432 (DB), 9090 (Prometheus)

---

## 2. Infrastructure Setup

### Base System

```bash
# Update system
sudo apt-get update && sudo apt-get upgrade -y

# Install dependencies
sudo apt-get install -y git build-essential curl postgresql-14
```

### Swift Installation

```bash
# Install Swift 5.9
wget https://download.swift.org/swift-5.9.2-release/ubuntu2204/swift-5.9.2-RELEASE/swift-5.9.2-RELEASE-ubuntu22.04.tar.gz
tar xz f swift-5.9.2-RELEASE-ubuntu22.04.tar.gz
sudo mv swift-5.9.2-RELEASE-ubuntu22.04 /usr/share/swift
echo "export PATH=/usr/share/swift/usr/bin:$PATH" >> ~/.bashrc
source ~/.bashrc
```

### Ollama Setup

```bash
curl https://ollama.ai/install.sh | sh
ollama pull llama2
ollama pull mistral
```

---

## 3. Database Setup

```bash
# Create user and db
sudo -u postgres createuser --interactive
sudo -u postgres createdb shared_kit_prod

# Initialize schema
./scripts/run_migrations.sh up production
```

---

## 4. Application Deployment

### Clone & Build

```bash
git clone https://github.com/dboone323/shared-kit.git
cd shared-kit
swift build -c release
```

### Service Configuration

Create `/etc/systemd/system/shared-kit.service`:

```ini
[Unit]
Description=Shared-Kit API Service
After=network.target postgresql.service ollama.service

[Service]
User=appuser
WorkingDirectory=/opt/shared-kit
ExecStart=/opt/shared-kit/.build/release/SharedKitAPI
Restart=always
EnvironmentFile=/etc/shared-kit/production.env

[Install]
WantedBy=multi-user.target
```

---

## 5. Operations

### Logging

Logs are sent to journald and file:

- `/var/log/shared-kit/access.log`
- `/var/log/shared-kit/error.log`

View logs:

```bash
journalctl -u shared-kit -f
tail -f /var/log/shared-kit/error.log
```

### Backup

Automated daily backups:

```bash
# Triggers pg_dump and config backup
/opt/shared-kit/scripts/backup_production.sh
```

Location: `s3://shared-kit-backups/` or `/mnt/backups/`

### Rollback

If deployment fails:

```bash
# Run rollback script
/opt/shared-kit/scripts/rollback_production.sh <previous_version_tag>
```

---

## 6. Monitoring & Health

### Health Check

Endpoint: `GET /health`

Response:

```json
{
  "status": "healthy",
  "version": "1.0.0",
  "services": {
    "database": "connected",
    "ollama": "connected"
  }
}
```

### Dashboard

Grafana available at: `http://monitoring.internal:3000`

---

## 7. Security Checklist

- [ ] Firewall enabled (UFW/AWS SG)
- [ ] Database password secured
- [ ] SSH key-based access only
- [ ] HTTPS enabled (Nginx/LettuceEncrypt)
- [ ] Secrets management active

---

**Status**: Ready for Deployment  
**Support**: oncall@example.com
