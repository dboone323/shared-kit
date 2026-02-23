# syntax=docker/dockerfile:1.5

# Build Stage
FROM swift:6.2 AS builder

WORKDIR /app

# Copy manifest files first to leverage build cache for dependencies
COPY Package.* ./
RUN --mount=type=cache,target=/root/.swiftpm swift package resolve

# Copy rest of sources and build using cache for SwiftPM
COPY . .
RUN --mount=type=cache,target=/root/.swiftpm swift build -c release

# Run Stage (Slim)
FROM swift:6.2-slim

WORKDIR /app

# Create non-root user
RUN groupadd -r swiftuser && useradd -r -g swiftuser -m swiftuser

# Copy built artifacts from builder
COPY --from=builder --chown=swiftuser:swiftuser /app .

USER swiftuser

# Default to running tests in dev images; production images should set a runtime command
CMD ["swift", "test"]
