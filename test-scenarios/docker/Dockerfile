FROM alpine:3.23

# Install basic tools
RUN apk add --no-cache \
    curl=8.12.1-r0 \
    bash=5.2.26-r0 \
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