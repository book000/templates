FROM alpine:3.18

# Install basic tools
RUN apk add --no-cache \
    curl \
    bash

# Create a simple test script
COPY test.sh /usr/local/bin/test.sh
RUN chmod +x /usr/local/bin/test.sh

# Set working directory
WORKDIR /app

# Default command
CMD ["/usr/local/bin/test.sh"]