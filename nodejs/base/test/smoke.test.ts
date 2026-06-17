/**
 * base バリアントのスモークテスト
 *
 * TypeScript の基本機能と Node.js 組み込みモジュールの動作を確認する。
 * 外部サービスへの接続は行わない。
 */

describe('TypeScript 基本機能', () => {
  it('async/await が動作する', async () => {
    const delay = (ms: number): Promise<string> =>
      new Promise((resolve) => setTimeout(() => resolve('ok'), ms))

    const result = await delay(0)
    expect(result).toBe('ok')
  })

  it('ジェネリクスが動作する', () => {
    function identity<T>(value: T): T {
      return value
    }
    expect(identity(42)).toBe(42)
    expect(identity('hello')).toBe('hello')
  })

  it('Error のスローと catch が動作する', async () => {
    const failingFn = async (): Promise<never> => {
      throw new Error('test error')
    }

    await expect(failingFn()).rejects.toThrow('test error')
  })
})
