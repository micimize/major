const { createPostGraphileSchema } = require('postgraphile')
const { options, pgConnectionConfig, SCHEMAS } = require('./options')
const { Pool } = require('pg')

async function main() {
  const pgPool = new Pool(pgConnectionConfig)
  await createPostGraphileSchema(pgPool, SCHEMAS, {
    ...options,
    writeCache: `${__dirname}/../dist/postgraphile.cache`,
  })
  await pgPool.end()
}

main().then(null, e => {
  // eslint-disable-next-line no-console
  console.error(e)
  process.exit(1)
})
