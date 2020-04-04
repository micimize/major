// this file needs to use `require` so that native nodejs scripts can consume it like makeCache
const simplify = require("@graphile-contrib/pg-simplify-inflector");
const upsert = require("graphile-upsert-plugin");
const upsertBatch = require("graphile-upsert-plugin/batch-allow-empty");

// We extract the environment verbosely to allow for webpack DefinePlugin to replace literals
/*
const DATABASE_URL =
  process.env.DATABASE_URL || 'postgres://localhost:5432/savvy'
*/
const DATABASE_HOST = process.env.DATABASE_HOST || "127.0.0.1";
const DATABASE_PORT = process.env.DATABASE_PORT || 5432;
const DATABASE_NAME = process.env.DATABASE_NAME || "todo_app";
const GOOGLE_CLIENT_IDS = process.env.GOOGLE_CLIENT_IDS || "";
const PORT = process.env.PORT || 5000;
const HOST = process.env.HOST || "localhost";
const NODE_ENV = process.env.NODE_ENV || "development";
const SCHEMAS = process.env.SCHEMAS || [process.env.SCHEMA || "public"];
const DATABASE_USER = process.env.DATABASE_USER;
const DATABASE_PASSWORD = process.env.DATABASE_PASSWORD;

const inDevMode = NODE_ENV.toLowerCase().startsWith("dev");

/*
const _posgresProtocol = inner => `postgresql://${inner}?ssl=false`

function postgresUri({
  DATABASE_USER: user,
  DATABASE_PASSWORD: password,
  DATABASE_HOST: host,
  DATABASE_PORT: port,
  DATABASE_NAME: database,
  omitLogin = false,
}) {
  if (omitLogin) {
    return _posgresProtocol(`${host}:${port}/${database}`)
  }
  user = encodeURIComponent(user)
  // TODO this still resulted in invalid password
  password = encodeURIComponent(password)

  return _posgresProtocol(`${user}:${password}@${host}:${port}/${database}`)
}

const _safeDbConnectionUri =
  DATABASE_USER && DATABASE_PASSWORD
    ? postgresUri({
        DATABASE_USER,
        DATABASE_PASSWORD,
        DATABASE_HOST,
        DATABASE_PORT,
        DATABASE_NAME,
        omitLogin: true,
      })
    : _posgresProtocol(
        DATABASE_URL.includes('@') ? DATABASE_URL.split('@')[1] : DATABASE_URL,
      )
exports.DATABASE_URL =
  DATABASE_USER && DATABASE_PASSWORD
    ? postgresUri({
        DATABASE_USER,
        DATABASE_PASSWORD,
        DATABASE_HOST,
        DATABASE_PORT,
        DATABASE_NAME,
      })
    : DATABASE_URL

*/

console.log(`Running with the following configuration:
  DATABASE 
    HOST=${DATABASE_HOST}
    PORT=${DATABASE_PORT}
    NAME=${DATABASE_NAME}
    SCHEMAS=${SCHEMAS} 
  NODE_ENV: ${NODE_ENV}
  GOOGLE_CLIENT_IDS: ${GOOGLE_CLIENT_IDS}
`);

exports.pgConnectionConfig = removeUnsuppied({
  host: DATABASE_HOST,
  port: DATABASE_PORT,
  user: DATABASE_USER,
  database: DATABASE_NAME,
  password: DATABASE_PASSWORD
});

// Remove invalid options
function removeUnsuppied(obj) {
  return Object.keys(obj).reduce(
    (valid, key) => (obj[key] ? { ...valid, [key]: obj[key] } : valid),
    {}
  );
}

exports.SCHEMAS = SCHEMAS;
exports.GOOGLE_CLIENT_IDS = GOOGLE_CLIENT_IDS.split(",");

exports.PORT = PORT;
exports.HOST = HOST;

exports.options = {
  dynamicJson: true,
  appendPlugins: [simplify, upsert, upsertBatch],
  watchPg: inDevMode,
  extendedErrors: inDevMode
    ? [
        "severity",
        "code",
        "detail",
        "hint",
        "positon",
        "internalPosition",
        "internalQuery",
        "where",
        "schema",
        "table",
        "column",
        "dataType",
        "constraint",
        "file",
        "line",
        "routine"
      ]
    : []
};
