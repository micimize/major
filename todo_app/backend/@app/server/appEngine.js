const fs = require("fs");
const path = require("path");

require("@app/config/extra");

/*
interface Secrets {
  DATABASE_INSTANCE: string;
  JWT_SECRET: string;
  GITHUB_KEY: string;
  GITHUB_SECRET: string;
  DATABASE_OWNER_PASSWORD: string;
  DATABASE_AUTHENTICATOR_PASSWORD: string;
}

interface Env {
  DATABASE_NAME: string;
  DATABASE_VISITOR: string;
  ENABLE_CYPRESS_COMMANDS?: string;
  ENABLE_GRAPHIQL?: string;
  GRAPHILE_LICENSE?: string;
  GRAPHQL_COST_LIMIT?: string;
  GRAPHQL_DEPTH_LIMIT?: string;
  GRAPHQL_PAGINATION_CAP?: string;
  HIDE_QUERY_COST?: string;
  MAXIMUM_SESSION_DURATION_IN_MILLISECONDS?: number;
  NODE_ENV: "development" | "production" | "test";
  REDIS_URL?: string;
  ROOT_URL: string;
  DEBUG?: string;
  PORT?: string;
}

type Config = Secrets & Env;
*/

const isUnsupplied = (value) => value === undefined || value === "";

// yaml key/value writer that excludes missing items
function optionYamlWriter(config /*: Config*/) {
  return (
    option /*: keyof Config*/,
    { default: defaultValue /*?: string*/, required /*?: bool*/ } = {}
  ) => {
    var value = config[option];
    if (isUnsupplied(value)) {
      value = defaultValue;
    }
    if (typeof value === "string") {
      value = `'${value}'`;
    }
    if (required && isUnsupplied(value)) {
      throw Error(`${option} is required, but not supplied`);
    }
    return isUnsupplied(value) ? "" : `${option}: ${value}`;
  };
}

/// builds the server app engine config
function appYaml(config /*: Config*/) {
  const writeAsYaml = optionYamlWriter(config);
  return `
beta_settings:
  cloud_sql_instances: '${config.DATABASE_INSTANCE}'

# [START runtime]
runtime: nodejs12
env: flex
entrypoint: node dist/index.js

# manual_scaling:
#   instances: 1
resources:
  cpu: .5
  memory_gb: .5
  disk_size_gb: 10

health_check:
  enable_health_check: False

# [END runtime]


env_variables:
  # Secrets 
  DATABASE_HOST: "/cloudsql/${config.DATABASE_INSTANCE}"
  DATABASE_URL: "socket:/cloudsql/${config.DATABASE_INSTANCE}?user=${
    config.DATABASE_OWNER
  }&password=${config.DATABASE_OWNER_PASSWORD}"
  ${writeAsYaml("DATABASE_INSTANCE", { required: true })}
  ${writeAsYaml("JWT_SECRET", { required: true })}
  ${writeAsYaml("GITHUB_KEY")}
  ${writeAsYaml("GITHUB_SECRET")}
  ${writeAsYaml("DATABASE_OWNER", {
    default: config.DATABASE_NAME,
  })}
  ${writeAsYaml("DATABASE_OWNER_PASSWORD", { required: true })}
  ${writeAsYaml("DATABASE_AUTHENTICATOR", {
    default: `${config.DATABASE_NAME}_authenticator`,
  })}
  ${writeAsYaml("DATABASE_AUTHENTICATOR_PASSWORD", { required: true })}


  # Env
  # PORT provided by app engine
  ${writeAsYaml("DATABASE_NAME", { required: true })}
  ${writeAsYaml("NODE_ENV", { default: "production" })}
  ${writeAsYaml("ROOT_URL")}
  ${writeAsYaml("DATABASE_VISITOR", config.DATABASE_NAME + "_visitor")}
  ${writeAsYaml("ENABLE_CYPRESS_COMMANDS")}
  ${writeAsYaml("ENABLE_GRAPHIQL")}
  ${writeAsYaml("GRAPHILE_LICENSE")}
  ${writeAsYaml("GRAPHQL_COST_LIMIT")}
  ${writeAsYaml("GRAPHQL_DEPTH_LIMIT")}
  ${writeAsYaml("GRAPHQL_PAGINATION_CAP")}
  ${writeAsYaml("HIDE_QUERY_COST")}
  ${writeAsYaml("MAXIMUM_SESSION_DURATION_IN_MILLISECONDS")}
  ${writeAsYaml("REDIS_URL")}
`;
}

fs.writeFileSync(path.join(__dirname, "app.yml"), appYaml(process.env));
