import Fastify from 'fastify'
import cors from '@fastify/cors'

/** Fastify インスタンス */
const fastify = Fastify({
  logger: true,
})

/**
 * エントリポイント
 */
async function main(): Promise<void> {
  await fastify.register(cors, {
    origin: true,
  })

  fastify.get('/', async (_request, _reply) => {
    return { status: 'ok' }
  })

  await fastify.listen({ port: 3000, host: '0.0.0.0' })
}

main().catch((error: unknown) => {
  fastify.log.error(error)
  process.exit(1)
})
