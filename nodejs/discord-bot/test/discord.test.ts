/**
 * discord-bot バリアントのテスト
 *
 * discord.js の Client が正しく初期化できること、および Discord クラスの
 * 基本動作を確認する。実際のトークンでのログインは行わない。
 */

import { Client, GatewayIntentBits } from 'discord.js'
import { Discord } from '../src/discord'
import type { ConfigFramework } from '@book000/node-utils'
import type { ConfigInterface } from '../src/config'

/** テスト用 ConfigFramework モック */
const createMockConfig = (): ConfigFramework<ConfigInterface> =>
  ({
    get: jest.fn(),
    load: jest.fn(),
    validate: jest.fn().mockReturnValue(true),
    getValidateFailures: jest.fn().mockReturnValue([]),
  }) as unknown as ConfigFramework<ConfigInterface>

describe('Discord クラス', () => {
  let client: Client

  beforeEach(() => {
    client = new Client({ intents: [GatewayIntentBits.Guilds] })
  })

  afterEach(() => {
    client.destroy()
  })

  it('Discord インスタンスを作成できる', () => {
    const mockConfig = createMockConfig()
    const discord = new Discord(client, mockConfig)
    expect(discord).toBeDefined()
  })

  it('onReady() を呼び出せる', () => {
    const mockConfig = createMockConfig()
    const discord = new Discord(client, mockConfig)
    const consoleSpy = jest.spyOn(console, 'log').mockImplementation()

    expect(() => discord.onReady()).not.toThrow()

    consoleSpy.mockRestore()
  })
})

describe('discord.js Client', () => {
  it('Client インスタンスを作成できる', () => {
    const testClient = new Client({ intents: [GatewayIntentBits.Guilds] })
    expect(testClient).toBeDefined()
    testClient.destroy()
  })

  it('複数の Intent を設定できる', () => {
    const testClient = new Client({
      intents: [
        GatewayIntentBits.Guilds,
        GatewayIntentBits.GuildMessages,
        GatewayIntentBits.MessageContent,
      ],
    })
    expect(testClient).toBeDefined()
    testClient.destroy()
  })
})
