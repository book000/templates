/**
 * config-batch バリアントのテスト
 *
 * @book000/node-utils の ConfigFramework が正しくサブクラス化できること、
 * およびバリデーションロジックが期待通りに動作することを確認する。
 * 外部サービスへの接続は行わない。
 */

import * as fs from 'node:fs'
import * as os from 'node:os'
import * as path from 'node:path'
import { ConfigFramework } from '@book000/node-utils'

/** テスト用の設定インターフェース */
interface TestConfig {
  apiKey: string
  timeout: number
}

/** テスト用の ConfigFramework 実装 */
class TestConfiguration extends ConfigFramework<TestConfig> {
  protected validates(): Record<string, (config: TestConfig) => boolean> {
    return {
      // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
      'apiKey is required': (config) => config.apiKey !== undefined,
      'apiKey is string': (config) => typeof config.apiKey === 'string',
      // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
      'timeout is required': (config) => config.timeout !== undefined,
      'timeout is positive number': (config) =>
        typeof config.timeout === 'number' && config.timeout > 0,
    }
  }
}

describe('ConfigFramework', () => {
  let tmpDir: string
  let configPath: string

  beforeEach(() => {
    tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'node-utils-test-'))
    configPath = path.join(tmpDir, 'config.json')
  })

  afterEach(() => {
    fs.rmSync(tmpDir, { recursive: true })
  })

  it('サブクラスを定義できる', () => {
    fs.writeFileSync(configPath, JSON.stringify({ apiKey: 'test', timeout: 30 }))
    const config = new TestConfiguration(configPath)
    expect(config).toBeDefined()
  })

  it('有効な設定を検証できる', () => {
    fs.writeFileSync(
      configPath,
      JSON.stringify({ apiKey: 'test-key', timeout: 30 })
    )
    const config = new TestConfiguration(configPath)
    config.load()
    expect(config.validate()).toBe(true)
    expect(config.getValidateFailures()).toHaveLength(0)
  })

  it('無効な設定を検出できる（負のタイムアウト）', () => {
    fs.writeFileSync(
      configPath,
      JSON.stringify({ apiKey: 'test-key', timeout: -1 })
    )
    const config = new TestConfiguration(configPath)
    config.load()
    expect(config.validate()).toBe(false)
    expect(config.getValidateFailures().length).toBeGreaterThan(0)
    expect(config.getValidateFailures()).toContain('timeout is positive number')
  })
})
