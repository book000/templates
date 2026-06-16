import { Client, GatewayIntentBits } from 'discord.js'
import { readFileSync } from 'node:fs'
import { ConfigInterface } from './config'
import { Discord } from './discord'

/**
 * 設定ファイルを読み込む
 */
function loadConfig(path: string): ConfigInterface {
  const raw = readFileSync(path, 'utf8')
  return JSON.parse(raw) as ConfigInterface
}

/**
 * エントリポイント
 */
async function main(): Promise<void> {
  const config = loadConfig('./data/config.json')

  const client = new Client({
    intents: [GatewayIntentBits.Guilds],
  })

  const discord = new Discord(client, config)

  client.once('ready', () => {
    console.log(`Logged in as ${client.user?.tag ?? 'unknown'}`)
    discord.onReady()
  })

  await client.login(config.token)
}

main().catch((error: unknown) => {
  console.error(error)
  process.exit(1)
})
