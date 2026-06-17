import { Client } from 'discord.js'
import { ConfigFramework } from '@book000/node-utils'
import { ConfigInterface } from './config'

/**
 * Discord Bot のメインクラス
 */
export class Discord {
  private readonly client: Client
  private readonly config: ConfigFramework<ConfigInterface>

  /**
   * @param client - Discord クライアント
   * @param config - 設定フレームワーク
   */
  constructor(client: Client, config: ConfigFramework<ConfigInterface>) {
    this.client = client
    this.config = config
  }

  /**
   * 設定フレームワークを返す
   */
  protected getConfig(): ConfigFramework<ConfigInterface> {
    return this.config
  }

  /**
   * Bot の準備完了時に呼ばれる
   */
  public onReady(): void {
    console.log(`Logged in as ${this.client.user?.tag ?? 'unknown'}`)
    // TODO: this.getConfig().get('key') で設定値を取得して処理を実装する
  }
}
