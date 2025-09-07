FROM alpine:3.20

# Install basic tools
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
USER appuser

# Default command
CMD ["/usr/local/bin/test.sh"]