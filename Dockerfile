# syntax=docker/dockerfile:1.5
# shared-kit - Linux source image for split-platform CI

FROM swift:6.2 AS builder

WORKDIR /app

# Resolve dependencies for Linux-side validation; full app/executable builds run on macOS CI.
COPY Package.* ./
RUN --mount=type=cache,target=/root/.swiftpm,id=swiftpm \
    swift package resolve

COPY . .

FROM swift:6.2-slim

LABEL maintainer="tools-automation"
LABEL description="Shared-Kit source workspace (Linux tooling image)"
LABEL org.opencontainers.image.source="https://github.com/tools-automation/shared-kit"
LABEL org.opencontainers.image.documentation="https://github.com/tools-automation/shared-kit/wiki"

WORKDIR /workspace

RUN groupadd -r libuser && useradd -r -g libuser -u 1001 libuser

COPY --from=builder --chown=libuser:libuser /app /workspace

USER libuser

HEALTHCHECK --interval=60s --timeout=10s --start-period=5s --retries=3 \
    CMD test -f /workspace/Package.swift || exit 1

CMD ["/bin/sh", "-lc", "echo 'shared-kit source container ready (macOS builds app binaries)'; sleep infinity"]
