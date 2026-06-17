import Fastify from 'fastify'
import cors from '@fastify/cors'
// fastify-raw-body は生の POST ボディが必要な場合に利用する（Webhook 署名検証など）
// import fastifyRawBody from 'fastify-raw-body'

/** Fastify インスタンス */
const fastify = Fastify({
  logger: true,
})

/**
 * エントリポイント
 */
async function main(): Promise<void> {
  await fastify.register(cors, {
    // TODO: 本番環境では許可するオリジンを明示的に設定すること（例: origin: 'https://example.com'）
    origin: false,
  })

  // fastify-raw-body を使う場合は以下を有効にする
  // await fastify.register(fastifyRawBody)

  fastify.get('/', (): { status: string } => {
    return { status: 'ok' }
  })

  await fastify.listen({ port: 3000, host: '0.0.0.0' })
}

main().catch((error: unknown) => {
  fastify.log.error(error)
  // eslint-disable-next-line unicorn/no-process-exit
  process.exit(1)
})
