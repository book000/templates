import { Client } from 'discord.js'
import { ConfigFramework } from '@book000/node-utils'
import { ConfigInterface } from './config'

/**
 * Discord Bot のメインクラス
 */
export class Discord {
  private readonly client: Client
  private readonly config: ConfigFramework<ConfigInterface>

  constructor(client: Client, config: ConfigFramework<ConfigInterface>) {
    this.client = client
    this.config = config
  }

  /**
   * Bot の準備完了時に呼ばれる
   */
  public onReady(): void {
    console.log('Discord bot is ready')
    // TODO: 実装
    // 設定値へのアクセス例: this.config.get('token')
  }
}
