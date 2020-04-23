#!/usr/bin/env node

// https://github.com/graphile/starter/blob/master/scripts/setup.js
// but only the database part
if (parseInt(process.version.split(".")[0], 10) < 10) {
  throw new Error("This project requires Node.js >= 10.0.0");
}

require(`${__dirname}/../../config/env`);

const inquirer = require("inquirer");
const pg = require("pg");

// fixes runSync not throwing ENOENT on windows
const platform = require("os").platform();
const yarnCmd = platform === "win32" ? "yarn.cmd" : "yarn";

const projectName = process.argv[2];

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

const { spawnSync } = require("child_process");

const runSync = (cmd, args, options = {}) => {
  const result = spawnSync(cmd, args, {
    stdio: ["inherit", "inherit", "inherit"],
    windowsHide: true,
    ...options,
    env: {
      ...process.env,
      YARN_SILENT: "1",
      npm_config_loglevel: "silent",
      ...options.env,
    },
  });

  const { error, status, signal, stderr, stdout } = result;

  if (error) {
    throw error;
  }

  if (status || signal) {
    if (stdout) {
      console.log(stdout.toString("utf8"));
    }
    if (stderr) {
      console.error(stderr.toString("utf8"));
    }
    if (status) {
      process.exitCode = status;
      throw new Error(
        `Process exited with status '${status}' (running '${cmd} ${
          args ? args.join(" ") : ""
        }')`
      );
    } else {
      throw new Error(
        `Process exited due to signal '${signal}' (running '${cmd} ${
          args ? args.join(" ") : null
        }')`
      );
    }
  }

  return result;
};

async function main() {
  const {
    DATABASE_AUTHENTICATOR,
    DATABASE_AUTHENTICATOR_PASSWORD,
    DATABASE_NAME,
    DATABASE_OWNER,
    DATABASE_OWNER_PASSWORD,
    DATABASE_VISITOR,
    ROOT_DATABASE_URL,
    CONFIRM_DROP,
  } = process.env;

  if (!CONFIRM_DROP) {
    const confirm = await inquirer.prompt([
      {
        type: "confirm",
        name: "CONFIRM",
        default: false,
        message: `We're going to drop (if necessary):
  - database ${DATABASE_NAME}
  - database ${DATABASE_NAME}_shadow
  - database role ${DATABASE_VISITOR} (cascade)
  - database role ${DATABASE_AUTHENTICATOR} (cascade)
  - database role ${DATABASE_OWNER}`,
      },
    ]);
    if (!confirm.CONFIRM) {
      console.error("Confirmation failed; exiting");
      process.exit(1);
    }
  }

  console.log("Installing or reinstalling the roles and database...");
  const pgPool = new pg.Pool({
    connectionString: ROOT_DATABASE_URL,
  });

  pgPool.on("error", (err) => {
    // Ignore
    console.log(
      "An error occurred whilst trying to talk to the database: " + err.message
    );
  });

  // Wait for PostgreSQL to come up
  let attempts = 0;
  while (true) {
    try {
      await pgPool.query('select true as "Connection test";');
      break;
    } catch (e) {
      if (e.code === "28P01") {
        throw e;
      }
      attempts++;
      if (attempts <= 30) {
        console.log(
          `Database is not ready yet (attempt ${attempts}): ${e.message}`
        );
      } else {
        console.log(`Database never came up, aborting :(`);
        process.exit(1);
      }
      await sleep(1000);
    }
  }

  const client = await pgPool.connect();
  try {
    // RESET database
    await client.query(`DROP DATABASE IF EXISTS ${DATABASE_NAME};`);
    await client.query(`DROP DATABASE IF EXISTS ${DATABASE_NAME}_shadow;`);
    await client.query(`DROP DATABASE IF EXISTS ${DATABASE_NAME}_test;`);
    await client.query(`DROP ROLE IF EXISTS ${DATABASE_VISITOR};`);
    await client.query(`DROP ROLE IF EXISTS ${DATABASE_AUTHENTICATOR};`);
    await client.query(`DROP ROLE IF EXISTS ${DATABASE_OWNER};`);

    // Now to set up the database cleanly:
    // Ref: https://devcenter.heroku.com/articles/heroku-postgresql#connection-permissions

    // This is the root role for the database`);
    await client.query(
      // IMPORTANT: don't grant SUPERUSER in production, we only need this so we can load the watch fixtures!
      `CREATE ROLE ${DATABASE_OWNER} WITH LOGIN PASSWORD '${DATABASE_OWNER_PASSWORD}' SUPERUSER;`
    );

    // This is the no-access role that PostGraphile will run as by default`);
    await client.query(
      `CREATE ROLE ${DATABASE_AUTHENTICATOR} WITH LOGIN PASSWORD '${DATABASE_AUTHENTICATOR_PASSWORD}' NOINHERIT;`
    );

    // This is the role that PostGraphile will switch to (from ${DATABASE_AUTHENTICATOR}) during a GraphQL request
    await client.query(`CREATE ROLE ${DATABASE_VISITOR};`);

    // This enables PostGraphile to switch from ${DATABASE_AUTHENTICATOR} to ${DATABASE_VISITOR}
    await client.query(
      `GRANT ${DATABASE_VISITOR} TO ${DATABASE_AUTHENTICATOR};`
    );
  } finally {
    await client.release();
  }
  await pgPool.end();

  runSync(yarnCmd, ["reset", "--erase"]);
  runSync(yarnCmd, ["reset", "--shadow", "--erase"]);

  console.log();
  console.log();
  console.log("____________________________________________________________");
  console.log();
  console.log();
  console.log("✅ Setup success");
  console.log();

  console.log("🚀 To get started, run:");
  console.log();
  if (projectName) {
    // Probably Docker setup
    console.log("  export UID; docker-compose up server");
  } else {
    console.log("  yarn start");
  }

  console.log();
  console.log(
    "🙏 Please support our Open Source work: https://graphile.org/sponsor"
  );
  console.log();
  console.log("____________________________________________________________");
  console.log();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
