FROM alpine:3.24

ARG APPLICATION_VERSION=unknown
ARG GIT_REVISION=unknown
ARG BUILD_TIME=unknown

# Verify that reusable-docker.yml passes the build metadata to every Docker build.
RUN test "$APPLICATION_VERSION" != "unknown" \
    && test "$GIT_REVISION" != "unknown" \
    && test "$BUILD_TIME" != "unknown"

# hadolint ignore=DL3018
RUN apk add --no-cache \
    curl \
    bash \
    && addgroup -g 1000 appgroup \
    && adduser -u 1000 -G appgroup -s /bin/bash -D appuser

COPY test.sh /usr/local/bin/test.sh
RUN chmod +x /usr/local/bin/test.sh

WORKDIR /app

RUN chown -R appuser:appgroup /app

USER 1000:1000

CMD ["/usr/local/bin/test.sh"]
