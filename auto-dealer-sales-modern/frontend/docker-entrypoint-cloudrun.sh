#!/bin/sh
# Substitute BACKEND_URL into the nginx config template at container start.
# Cloud Run injects $BACKEND_URL via --set-env-vars when the frontend
# service is deployed, pointing at the backend Cloud Run URL.
set -e

: "${BACKEND_URL:?BACKEND_URL must be set}"

envsubst '${BACKEND_URL}' \
    < /etc/nginx/conf.d/default.conf.template \
    > /etc/nginx/conf.d/default.conf

exec nginx -g 'daemon off;'
