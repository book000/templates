import { ConfigFramework } from '@book000/node-utils'
import { ConfigInterface } from './config'

/**
 * 設定フレームワーク実装
 */
class Configuration extends ConfigFramework<ConfigInterface> {
  /**
   * バリデーションルールを返す
   */
  protected validates(): Record<string, (config: ConfigInterface) => boolean> {
    return {
      // TODO: バリデーションルールを追加する
      // 例: 'someKey is required': (config) => config.someKey !== undefined,
    }
  }
}

/**
 * エントリポイント
 */
// eslint-disable-next-line @typescript-eslint/require-await
async function main(): Promise<void> {
  const config = new Configuration('./data/config.json')
  config.load()
  if (!config.validate()) {
    throw new Error(
      `Configuration validation failed: ${config.getValidateFailures().join(', ')}`
    )
  }
  // TODO: config.get('key') でアクセスして処理を実装する
}

main().catch((error: unknown) => {
  console.error(error)
  // eslint-disable-next-line unicorn/no-process-exit
  process.exit(1)
})
