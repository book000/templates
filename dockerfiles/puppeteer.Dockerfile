FROM node:20-alpine as builder

WORKDIR /app

COPY package.json yarn.lock ./

RUN echo network-timeout 600000 > .yarnrc && \
  yarn install --frozen-lockfile && \
  yarn cache clean

COPY src/ src/
COPY tsconfig.json .

RUN yarn package

FROM zenika/alpine-chrome:with-puppeteer AS runner

# hadolint ignore=DL3002
USER root

WORKDIR /app

COPY --from=builder /app/output .

COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

ENV TZ Asia/Tokyo
ENV CHROMIUM_PATH /usr/bin/chromium-browser

ENTRYPOINT ["tini", "--"]
CMD ["/app/entrypoint.sh"]