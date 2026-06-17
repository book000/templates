/**
 * fastify バリアントのテスト
 *
 * Fastify + @fastify/cors が正しく動作することを確認する。
 * 実際のポートへのバインドは行わず、inject() でリクエストを注入する。
 */

import Fastify from 'fastify'
import cors from '@fastify/cors'

describe('Fastify アプリケーション', () => {
  it('Fastify インスタンスを作成できる', () => {
    const app = Fastify()
    expect(app).toBeDefined()
    void app.close()
  })

  it('@fastify/cors を登録できる', async () => {
    const app = Fastify()
    await app.register(cors, { origin: false })
    expect(app).toBeDefined()
    await app.close()
  })

  it('GET / が 200 を返す', async () => {
    const app = Fastify()
    await app.register(cors, { origin: false })

    app.get('/', async (_request, _reply) => {
      return { status: 'ok' }
    })

    const response = await app.inject({ method: 'GET', url: '/' })
    expect(response.statusCode).toBe(200)
    expect(JSON.parse(response.body)).toEqual({ status: 'ok' })

    await app.close()
  })

  it('存在しないルートが 404 を返す', async () => {
    const app = Fastify()
    await app.register(cors, { origin: false })

    const response = await app.inject({ method: 'GET', url: '/nonexistent' })
    expect(response.statusCode).toBe(404)

    await app.close()
  })
})
