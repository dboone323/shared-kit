# Shared-Kit Environment Variables

## Required Environment Variables

### Database Configuration

```bash
# PostgreSQL Database Password
export POSTGRES_PASSWORD="your-secure-password-here"
```

**Security Notes**:

- ⚠️ **Never commit passwords to version control**
- ✅ Use different passwords for dev/staging/production
- ✅ Rotate passwords regularly
- ✅ Use strong passwords (16+ characters, mixed case, numbers, symbols)

## Setting Environment Variables

### Development (Xcode)

1. Open your scheme settings: **Product → Scheme → Edit Scheme**
2. Select **Run** → **Arguments** tab
3. Add to **Environment Variables**:
   - Name: `POSTGRES_PASSWORD`
   - Value: `your-dev-password`
4. **Do not** check "Add to version control"

### Production (macOS)

```bash
# Add to ~/.zshrc or ~/.bashrc
export POSTGRES_PASSWORD="production-password"

# Or use launchd plist for agents
```

### CI/CD

Set as secure environment variables in your CI system:

- GitHub Actions: Repository Secrets
- GitLab CI: CI/CD Variables (masked)
- Jenkins: Credentials

## Validation

The application will use an empty string if `POSTGRES_PASSWORD` is not set. To validate:

```swift
if let password = ProcessInfo.processInfo.environment["POSTGRES_PASSWORD"], !password.isEmpty {
    print("✅ Database password configured")
} else {
    print("⚠️ WARNING: POSTGRES_PASSWORD not set!")
}
```

## Migration from Hardcoded Password

**Old (INSECURE)**:

```swift
password: "sonar",  // ❌ NEVER DO THIS
```

**New (SECURE)**:

```swift
password: ProcessInfo.processInfo.environment["POSTGRES_PASSWORD"] ?? "",  // ✅
```

## Security Best Practices

1. **Immediate Actions**:

   - ✅ Passwords removed from code (completed)
   - ⚠️ Rotate "sonar" password on all databases
   - ⚠️ Review git history for exposed credentials

2. **Ongoing**:
   - Use password managers for team access
   - Implement secrets management (AWS Secrets Manager, HashiCorp Vault)
   - Monitor for credential exposure
   - Regular security audits

## Troubleshooting

### "Database connection failed"

- Check `POSTGRES_PASSWORD` is set: `echo $POSTGRES_PASSWORD`
- Verify password is correct
- Ensure no trailing spaces

### "Empty password"

- Environment variable not set in current session
- Xcode scheme not configured
- Check shell profile is loaded

## Additional Database Environment Variables

Consider also externalizing:

```bash
export POSTGRES_HOST="localhost"
export POSTGRES_PORT="5432"
export POSTGRES_USER="postgres"
export POSTGRES_DATABASE="yourdb"
```

---

**Last Updated**: 2026-01-15  
**Security Level**: CRITICAL
