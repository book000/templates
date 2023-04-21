FROM node:19-alpine as builder

WORKDIR /app

COPY package.json .
COPY yarn.lock .

RUN echo network-timeout 600000 > .yarnrc && \
  yarn install --frozen-lockfile && \
  yarn cache clean

COPY src src
COPY tsconfig.json .

RUN yarn package

FROM zenika/alpine-chrome:with-puppeteer AS runner

WORKDIR /app

COPY --from=builder /app/output .

COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

ENV TZ Asia/Tokyo
ENV CHROMIUM_PATH=/usr/bin/chromium-browser

ENTRYPOINT ["tini", "--"]
CMD ["/app/entrypoint.sh"]