import { Pool } from "pg";
import { Express } from "express";
import { getShutdownActions } from "../app";

export function getRootPgPool(app: Express): Pool {
  return app.get("rootPgPool");
}
export function getAuthPgPool(app: Express): Pool {
  return app.get("authPgPool");
}

/**
 * When a PoolClient omits an 'error' event that cannot be caught by a promise
 * chain (e.g. when the PostgreSQL server terminates the link but the client
 * isn't actively being used) the error is raised via the Pool. In Node.js if
 * an 'error' event is raised and it isn't handled, the entire process exits.
 * This NOOP handler avoids this occurring on our pools.
 *
 * TODO: log this to an error reporting service.
 */
function swallowPoolError(_error: Error) {
  /* noop */
}

export default (app: Express) => {
  const env = process.env;
  const databaseParams = {
    host: env.DATABASE_HOST || "localhost",
    port: parseInt(env.DATABASE_PORT || "5432"),
    database: env.DATABASE_NAME,
  };

  // This pool runs as the database owner, so it can do anything.
  const rootPgPool = new Pool({
    ...databaseParams,
    user: env.DATABASE_OWNER,
    password: env.DATABASE_OWNER_PASSWORD,
  });
  rootPgPool.on("error", swallowPoolError);
  app.set("rootPgPool", rootPgPool);

  // This pool runs as the unprivileged user, it's what PostGraphile uses.
  const authPgPool = new Pool({
    ...databaseParams,
    user: env.DATABASE_AUTHENTICATOR,
    password: env.DATABASE_AUTHENTICATOR_PASSWORD,
  });
  authPgPool.on("error", swallowPoolError);
  app.set("authPgPool", authPgPool);

  const shutdownActions = getShutdownActions(app);
  shutdownActions.push(() => {
    rootPgPool.end();
  });
  shutdownActions.push(() => {
    authPgPool.end();
  });
};
