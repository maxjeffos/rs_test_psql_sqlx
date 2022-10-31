#!/usr/bin/env bash
set -x
set -eo pipefail

# Check if a custom user has been set, otherwise default to 'postgres'
DB_USER=${POSTGRES_USER:=postgres}

# Check if a custom password has been set, otherwise default to 'password'
DB_PASSWORD="${POSTGRES_PASSWORD:=password}"

# Check if a custom database name has been set, otherwise default to 'newsletter'
DB_NAME="${POSTGRES_DB:=newsletter}"

# Check if a custom port has been set, otherwise default to '5432'
DB_PORT="${POSTGRES_PORT:=5432}"

# Launch postgres using Docker
docker run \
  -e POSTGRES_USER=${DB_USER} \
  -e POSTGRES_PASSWORD=${DB_PASSWORD} \
  -e POSTGRES_DB=${DB_NAME} \
  -p "${DB_PORT}":5432 \
  -d postgres \
  postgres -N 1000
  # ^ Increased maximum number of connections for testing purposes

# Keep pinging Postgres until it's ready to accept commands
export PGPASSWORD="${DB_PASSWORD}"
# until psql -h "localhost" -U "${DB_USER}" -p "${DB_PORT}" -d "postgres" -c '\q'; do
#   >&2 echo "Postgres is still unavailable - sleeping"
# sleep 1 done
# >&2 echo "Postgres is up and running on port ${DB_PORT}!"

sleep 10

echo "\nshow docker containers:"
docker ps

# PSQL_CLI_CONNET_OPTIONS="-h \"localhost\" -U \"${DB_USER}\" -p ${DB_PORT} -d \"postgres\""
                                                                # the -d is for database. TODO align with db name
PSQL_CLI_CONNET_OPTIONS="-h 0.0.0.0 -U ${DB_USER} -p ${DB_PORT} -d postgres"
echo $PSQL_CLI_CONNET_OPTIONS

# DATABASE_URL is for sqlx
DATABASE_URL=postgres://${DB_USER}:${DB_PASSWORD}@localhost:${DB_PORT}/${DB_NAME}
echo $DATABASE_URL

# show databases
echo "\n show databases..."
psql $PSQL_CLI_CONNET_OPTIONS -c "\l"


# now use sqlx to create DB that doesn't exit yet
echo "make new db"
DB_NAME=mynewdb
DATABASE_URL=postgres://${DB_USER}:${DB_PASSWORD}@localhost:${DB_PORT}/${DB_NAME}
echo $DATABASE_URL
export DATABASE_URL

sqlx database create
echo "\n show databases..."
psql $PSQL_CLI_CONNET_OPTIONS -c "\l"  # psql show database

# use new database name for futre psql commands
PSQL_CLI_CONNET_OPTIONS="-h 0.0.0.0 -U ${DB_USER} -p ${DB_PORT} -d mynewdb"
echo "PSQL_CLI_CONNET_OPTIONS: ${PSQL_CLI_CONNET_OPTIONS}"

# sqlx migrate add create_user_table
sqlx migrate run

psql $PSQL_CLI_CONNET_OPTIONS -c "\c mynewdb" # switch to new db

echo "showing schemas..."
psql $PSQL_CLI_CONNET_OPTIONS -c "\dn"  # show schemas

echo "showing tables..."
psql $PSQL_CLI_CONNET_OPTIONS -c "\dt public.*"  # show tables in schema `public`
