import { Client } from 'discord.js'
import { ConfigInterface } from './config'

/**
 * Discord Bot のメインクラス
 */
export class Discord {
  private readonly client: Client
  private readonly config: ConfigInterface

  constructor(client: Client, config: ConfigInterface) {
    this.client = client
    this.config = config
  }

  /**
   * Bot の準備完了時に呼ばれる
   */
  public onReady(): void {
    console.log('Discord bot is ready')
    // TODO: 実装
  }
}
