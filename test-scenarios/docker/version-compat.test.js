const assert = require('node:assert/strict')
const fs = require('node:fs')
const path = require('node:path')

const workflowPath = path.join(
  __dirname,
  '../../.github/workflows/reusable-docker.yml'
)
const workflow = fs.readFileSync(workflowPath, 'utf8')
const AsyncFunction = Object.getPrototypeOf(async function () {}).constructor

function scriptFor(id) {
  const step = workflow
    .split(/\n      - name: /)
    .find((section) => section.includes(`\n        id: ${id}\n`))
  assert.ok(step, `Missing step ${id}`)
  const script = step.split('\n          script: |\n')[1]
  assert.ok(script, `Missing script in ${id}`)
  return script
    .split('\n')
    .map((line) => line.startsWith('            ') ? line.slice(12) : line)
    .join('\n')
}

async function execute(id, env, options = {}) {
  const { eventName = 'pull_request_target', ref = 'refs/heads/main', exists = false } = options
  const saved = { ...process.env }
  Object.assign(process.env, env)
  const outputs = {}
  const calls = []
  const context = {
    eventName,
    ref,
    sha: 'b'.repeat(40),
    repo: { owner: 'owner', repo: 'repo' },
  }
  const core = { setOutput: (key, value) => { outputs[key] = value } }
  const github = {
    rest: {
      git: {
        getRef: async (args) => {
          calls.push(['getRef', args])
          if (!exists) throw { status: 404 }
        },
        createRef: async (args) => { calls.push(['createRef', args]) },
      },
    },
  }
  try {
    await new AsyncFunction('github', 'context', 'core', scriptFor(id))(
      github, context, core
    )
    return { outputs, calls }
  } finally {
    process.env = saved
  }
}

async function main() {
  for (const [calculated, custom, expected] of [
    ['1.2.4-bbbbbbb', '', '1.2.4'],
    ['1.3.0-bbbbbbb', '', '1.3.0'],
    ['2.4.0-bbbbbbb', '2.4.0-bbbbbbb', '2.4.0-bbbbbbb'],
    ['release-candidate', 'release-candidate', 'release-candidate'],
  ]) {
    const result = await execute('select-version', {
      CALCULATED_VERSION: calculated,
      CUSTOM_VERSION: custom,
    })
    assert.equal(result.outputs.version, expected)
  }
  await assert.rejects(
    execute('select-version', {
      CALCULATED_VERSION: '1.2.4', CUSTOM_VERSION: '',
    }),
    /unexpected suffix/
  )

  const env = {
    VERSION: '1.2.4',
    TAG: 'v1.2.4',
    CHANGELOG: 'Notes\nMore notes',
    IS_MERGED: 'true',
  }
  const published = await execute('tag-version', env)
  assert.deepEqual(published.outputs, {
    new_version: env.VERSION, new_tag: env.TAG, changelog: env.CHANGELOG,
  })
  assert.deepEqual(published.calls.map(([name]) => name), ['getRef', 'createRef'])
  assert.equal(published.calls[1][1].sha, 'b'.repeat(40))
  assert.equal(published.calls[1][1].ref, 'refs/tags/v1.2.4')
  const existing = await execute('tag-version', env, { exists: true })
  assert.deepEqual(existing.calls.map(([name]) => name), ['getRef'])
  const dryRun = await execute('tag-version', { ...env, IS_MERGED: 'false' })
  assert.deepEqual(dryRun.calls, [])
  console.log('Version compatibility checks passed')
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
