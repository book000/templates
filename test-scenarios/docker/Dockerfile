FROM alpine:3.24

ARG APPLICATION_VERSION=unknown
ARG GIT_REVISION=unknown
ARG BUILD_TIME=unknown

# reusable-docker.yml が build metadata を各 Docker build へ渡すことを検証する。
RUN test "$APPLICATION_VERSION" != "unknown" \
    && test "$GIT_REVISION" != "unknown" \
    && test "$BUILD_TIME" != "unknown"

# Install basic tools
# hadolint ignore=DL3018
RUN apk add --no-cache \
    curl \
    bash \
    && addgroup -g 1000 appgroup \
    && adduser -u 1000 -G appgroup -s /bin/bash -D appuser

# Create a simple test script
COPY test.sh /usr/local/bin/test.sh
RUN chmod +x /usr/local/bin/test.sh

# Set working directory
WORKDIR /app

# Change ownership to non-root user
RUN chown -R appuser:appgroup /app

# Switch to non-root user
USER 1000:1000

# Default command
CMD ["/usr/local/bin/test.sh"]
