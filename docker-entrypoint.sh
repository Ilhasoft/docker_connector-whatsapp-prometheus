#!/bin/bash

set -e

parse_env(){
	if [ -r "$1" ] ; then
		while IFS="=" read key value  ; do
			export "${key}=${value}"
		done<<<"$( egrep '^[^#]+=.*' "$1" )"
	fi
}

bootstrap_conf(){
	if [ "${TZ}" ] ; then
		ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime && echo "${TZ}" > /etc/timezone
	fi
	find /app -not -user app_user -exec chown app_user:app_group {} \+
}

parse_env '/env.sh'
parse_env '/run/secrets/env.sh'

bootstrap_conf

if [[ "start" == "$1" ]]; then
	exec gosu app_user gunicorn --bind "0.0.0.0:${APP_PORT}" --capture-output --error-logfile - --log-level debug "main:app" --max-requests 1000 --keep-alive 6 --max-requests-jitter 100
elif [[ "healthcheck" == "$1" ]]; then
	gosu app_user curl -SsLf "http://127.0.0.1:${APP_PORT}/health" -o /tmp/null --connect-timeout 3 --max-time 20 -w "%{http_code} %{http_version} %{response_code} %{time_total}\n" || exit 1
	exit 0
fi

exec "$@"

