FROM node:20-alpine

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME/bin:$PATH"

# hadolint ignore=DL3018
RUN apk update && \
  apk upgrade && \
  apk add --update --no-cache tzdata && \
  cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
  echo "Asia/Tokyo" > /etc/timezone && \
  apk del tzdata && \
  npm install -g corepack@latest && \
  pnpm approve-builds && \
  corepack enable

WORKDIR /app

COPY pnpm-lock.yaml ./

RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm fetch

COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

COPY package.json tsconfig.json ./
COPY src src

RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --frozen-lockfile --offline && \
  pnpm approve-builds

ENV NODE_ENV=production

ENTRYPOINT [ "/app/entrypoint.sh" ]