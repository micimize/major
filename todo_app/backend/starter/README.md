A stripped down version of the [graphile-starter](https://github.com/graphile/starter) with just the backend components

## Packages

- [@app/server](./server/README.md) - the Node.js backend and tests, powered by
  [Express](https://expressjs.com/), [Passport](http://www.passportjs.org/) and
  [PostGraphile](https://www.graphile.org/postgraphile/) (provides auth,
  GraphQL, SSR, etc)
- [@app/worker](./worker/README.md) - job queue (e.g. for sending emails),
  powered by [graphile-worker](https://github.com/graphile/worker)
- [@app/db](./db/README.md) - database migrations and tests, powered by
  [graphile-migrate](https://github.com/graphile/migrate)
- [@app/\_\_tests\_\_](./__tests__/README.md) - some test helpers
