#!/bin/sh
set -e

echo "Starting OpenProject container..."

# 1. Виконання міграцій
if [ "$MIGRATE_DB" = "yes" ]; then
  echo "Checking for pending migrations..."
  if bundle exec rails db:abort_if_pending_migrations RAILS_ENV=production; then
    echo "No pending migrations. Skipping..."
  else
    echo "Running database migrations..."
    bundle exec rails db:migrate RAILS_ENV=production
    bundle exec rails db:seed RAILS_ENV=production
  fi
else
  echo "Skipping database migrations."
fi


if [ "$PRECOMPILE_ASSETS" = "yes" ]; then
  echo "Precompiling assets..."
  RAILS_ENV=production bundle exec rake assets:precompile
  # if [ "$(ls -A /app/public/assets 2>/dev/null)" ]; then
  #   echo "Assets already precompiled. Skipping..."
  # else
else
  echo "Skipping assets precompilation."
fi

if [ "$CI" = "true" ]; then
  echo "Running linter (rubocop)..."
  bundle exec rubocop --fail-level E
  
  echo "CI checks passed successfully!"
fi

echo "Starting Puma server..."
exec bundle exec puma -C config/puma.rb -e production
