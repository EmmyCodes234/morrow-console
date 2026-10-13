#!/bin/sh
set -e

# Remove any stale server pid
rm -f /app/tmp/pids/server.pid

echo "==> Running database migrations..."
bundle exec rake db:migrate

echo "==> Starting lightweight Sidekiq worker (concurrency 2)..."
bundle exec sidekiq -c 2 -C config/sidekiq.yml &

echo "==> Starting Rails server on port ${PORT:-3000}..."
exec bundle exec rails server -b 0.0.0.0 -p ${PORT:-3000}
