/**
 * エントリポイント
 */
// eslint-disable-next-line @typescript-eslint/require-await
async function main(): Promise<void> {
  console.log('Hello, World!')
}

main().catch((error: unknown) => {
  console.error(error)
  // eslint-disable-next-line unicorn/no-process-exit
  process.exit(1)
})
