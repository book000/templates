FROM node:20-alpine as builder

WORKDIR /app

COPY package.json .
COPY yarn.lock .

RUN echo network-timeout 600000 > .yarnrc && \
  yarn install --frozen-lockfile && \
  yarn cache clean

COPY src src
COPY tsconfig.json .

RUN yarn package

FROM alpine:3.17 as runner

# hadolint ignore=DL3018
RUN apk upgrade --no-cache --available && \
  apk update && \
  apk add --no-cache \
  curl \
  fontconfig \
  font-noto-cjk \
  font-noto-emoji \
  && \
  fc-cache -fv && \
  apk add --no-cache \
  chromium-swiftshader \
  ttf-freefont \
  freetype \
  freetype-dev \
  harfbuzz \
  ca-certificates \
  tini \
  make \
  gcc \
  g++ \
  python3 \
  nodejs \
  npm \
  yarn \
  && \
  apk add --update --no-cache tzdata && \
  cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
  echo "Asia/Tokyo" > /etc/timezone && \
  apk del tzdata

WORKDIR /app

COPY --from=builder /app/output .

COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

ENV CHROMIUM_PATH /usr/bin/chromium-browser

ENTRYPOINT ["tini", "--"]
CMD ["/app/entrypoint.sh"]