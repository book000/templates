import { readFileSync } from 'node:fs'
import { ConfigInterface } from './config'

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
  // TODO: 実装
  console.log(config)
}

main().catch((error: unknown) => {
  console.error(error)
  process.exit(1)
})
