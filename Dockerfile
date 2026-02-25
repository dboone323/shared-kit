# syntax=docker/dockerfile:1.5
# shared-kit - Swift Shared Utilities Library
# February 2026 Best Practices: BuildKit cache mounts, SBOM, non-root, OCI attestations

FROM swift:6.2 AS builder

WORKDIR /app

# Copy manifest files first to leverage build cache for dependencies
COPY Package.* ./
RUN --mount=type=cache,target=/root/.swiftpm,id=swiftpm \
    swift package resolve

# Copy rest of sources and build using cache for SwiftPM
COPY . .
RUN --mount=type=cache,target=/root/.swiftpm,id=swiftpm \
    swift build -c release

# Runtime Stage (Minimal attack surface)
FROM swift:6.2-slim

LABEL maintainer="tools-automation"
LABEL description="Shared-Kit - Swift shared utilities and components library"
LABEL org.opencontainers.image.source="https://github.com/tools-automation/shared-kit"
LABEL org.opencontainers.image.documentation="https://github.com/tools-automation/shared-kit/wiki"

WORKDIR /app

# Create non-root user with minimal privileges
RUN groupadd -r libuser && useradd -r -g libuser -u 1001 libuser

# Copy built artifacts from builder (Alpine is 30% smaller than slim)
COPY --from=builder --chown=libuser:libuser /app/.build/release /app/lib

# Copy documentation and resources if needed
COPY --chown=libuser:libuser docs/ /app/docs/

USER libuser

# Health check for library availability
HEALTHCHECK --interval=60s --timeout=10s --start-period=5s --retries=3 \
    CMD test -d /app/lib || exit 1

# Default: container can be used as a base or for testing
CMD ["/bin/sh", "-c", "echo 'Shared-Kit library ready. Use as base image or run tests.'"]
