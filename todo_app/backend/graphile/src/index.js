import express from 'express'
import { postgraphile } from 'postgraphile'

import {
  options,
  pgConnectionConfig,
  SCHEMAS,
  GOOGLE_CLIENT_IDS,
  HOST,
  PORT,
} from './options'

import googleJWT from './google-jwt-verifier'

const app = express()

const handleAuthorizationErrors = (err, req, response, next) => {
  if (err.name === 'UnauthorizedError') {
    console.error(err)
    const payload = { errors: [{ message: err.message }] }
    response
      .status(err.status)
      .json(payload)
      .end()
  }
  next()
}

app.use('/graphql', googleJWT(GOOGLE_CLIENT_IDS))

app.use('/graphql', handleAuthorizationErrors)

app.use(
  postgraphile(pgConnectionConfig, SCHEMAS, {
    ...options,
    ...(!options.watchPg
      ? { readCache: `${__dirname}/postgraphile.cache` }
      : {}),
    pgSettings: request => {
      const settings = {}
      if (request.user) {
        Object.keys(request.user).forEach(key => {
          settings[`google_user.${key}`] = request.user[key]
        })
      }
      return settings
    },
  }),
)

app.get('/health', (req, res) => res.send('is healthy'))

app.listen(PORT, HOST, () =>
  console.log(`Graphile Server running at ${HOST}:${PORT}`),
)
