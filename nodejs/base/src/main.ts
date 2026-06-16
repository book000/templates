/**
 * エントリポイント
 */
async function main(): Promise<void> {
  console.log('Hello, World!')
}

main().catch((error: unknown) => {
  console.error(error)
  process.exit(1)
})
