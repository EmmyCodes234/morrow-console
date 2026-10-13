#!/bin/sh
set -e

# Remove any stale server pid
rm -f /app/tmp/pids/server.pid

echo "==> Running database setup (migrations & seeds)..."
bundle exec rake db:chatwoot_prepare

echo "==> Starting Sidekiq background worker..."
bundle exec sidekiq -C config/sidekiq.yml &

if [ $# -gt 0 ]; then
  echo "==> Executing command: $@"
  exec "$@"
else
  echo "==> Starting Rails server on port ${PORT:-3000}..."
  exec bundle exec rails server -b 0.0.0.0 -p ${PORT:-3000}
fi
