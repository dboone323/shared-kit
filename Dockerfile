# Build Stage
FROM swift:6.0 as builder

WORKDIR /app
COPY . .

# Resolve dependencies and build
RUN swift package resolve
RUN swift build -c release

# Run Stage (Slim)
FROM swift:6.0-slim

WORKDIR /app

# Create non-root user
RUN groupadd -r swiftuser && useradd -r -g swiftuser -m swiftuser

COPY --from=builder --chown=swiftuser:swiftuser /app .

USER swiftuser

CMD ["swift", "test"]
