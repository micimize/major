#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cd $DIR/../../

set -a # automatically export all variables
source $DIR/secrets.env
set +a

export GCP_SERVICE_ACCOUNT_KEY=$(
  base64 -i $DIR/deployment-service-account-key.json
)

# -s JWT_SECRET sets the value of JWT_SECRET in the current environment as a secret
act \
  -P ubuntu-latest=nektos/act-environments-ubuntu:18.04-lite \
  -s GCP_PROJECT_ID \
  -s GCP_SERVICE_ACCOUNT_EMAIL \
  -s GCP_SERVICE_ACCOUNT_KEY \
  -s DATABASE_INSTANCE \
  -s DATABASE_OWNER_PASSWORD \
  -s DATABASE_AUTHENTICATOR_PASSWORD \
  -s JWT_SECRET
