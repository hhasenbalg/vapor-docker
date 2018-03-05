#!/bin/bash
set -euo pipefail 

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
	local var="$1"
	local fileVar="${var}_FILE"

	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
		exit 1
	fi

	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
	fi
	export "$var"="$val"
	unset "$fileVar"
}

envs=(
	"HOME:home"	
	"POSTGRES_HOSTNAME	:postgresql.hostname"
	"POSTGRES_PORT		:postgresql.port"
	"POSTGRES_USER		:postgresql.user"
	"POSTGRES_PASSWORD	:postgresql.password"
	"POSTGRES_DB		:postgresql.database"
	"MYSQL_HOSTNAME		:mysql.hostname"
	"MYSQL_PORT			:mysql.port"
	"MYSQL_USER			:mysql.user"
	"MYSQL_PASSWORD		:mysql.password"
	"MYSQL_DB			:mysql.database"
	"PORT 				:server.port"
	"HASH_KEY			:crypto.hash.key"
	"CIPHER_KEY			:crypto.cipher.key")

prameters="serve"
for e in "${envs[@]}" ; do
    KEY="${e%%:*}"
    PARAM="${e##*:}"

	file_env "$KEY"
	if [ -n "${!KEY}" ]; then
		prameters="$prameters --config:$PARAM=${!KEY}"
	fi

    # printf "%s : %s. = %s\n" "$KEY" "$PARAM" "${!KEY}"
done

echo $prameters

./Run $prameters
