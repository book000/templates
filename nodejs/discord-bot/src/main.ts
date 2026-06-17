import { Client, GatewayIntentBits } from 'discord.js'
import { ConfigFramework } from '@book000/node-utils'
import { ConfigInterface } from './config'
import { Discord } from './discord'

/**
 * 設定フレームワーク実装
 */
class Configuration extends ConfigFramework<ConfigInterface> {
  /**
   * バリデーションルールを返す
   */
  protected validates(): Record<string, (config: ConfigInterface) => boolean> {
    return {
      // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
      'token is required': (config) => config.token !== undefined,
      'token is string': (config) => typeof config.token === 'string',
      // TODO: バリデーションルールを追加する
    }
  }
}

/**
 * エントリポイント
 */
async function main(): Promise<void> {
  const config = new Configuration('./data/config.json')
  config.load()
  if (!config.validate()) {
    throw new Error(
      `Configuration validation failed: ${config.getValidateFailures().join(', ')}`
    )
  }

  const client = new Client({
    intents: [GatewayIntentBits.Guilds],
  })

  const discord = new Discord(client, config)

  client.once('ready', () => {
    console.log(`Logged in as ${client.user?.tag ?? 'unknown'}`)
    discord.onReady()
  })

  await client.login(config.get('token'))
}

main().catch((error: unknown) => {
  console.error(error)
  // eslint-disable-next-line unicorn/no-process-exit
  process.exit(1)
})
