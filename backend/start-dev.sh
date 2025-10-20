#!/bin/bash
# Development startup script - Run migrations and start with hot reloading
# This ensures the database schema is always up-to-date on container start

set -e  # Exit immediately if a command exits with a non-zero status

echo "=== CSFrace Backend Development Startup ==="
echo "Environment: ${ENVIRONMENT:-development}"
echo "Running database migrations..."

# Run Alembic migrations using uv (explicitly specify config file)
uv run alembic -c /build/alembic.ini upgrade head

echo "Migrations complete!"
echo "Starting development server with hot reloading..."

# Start uvicorn with reload for development using uv
# Convert LOG_LEVEL to lowercase for uvicorn
LOG_LEVEL_LOWER=$(echo "${LOG_LEVEL:-debug}" | tr '[:upper:]' '[:lower:]')
exec uv run uvicorn src.api.main:app \
    --host 0.0.0.0 \
    --port "${BACKEND_PORT:-8000}" \
    --reload \
    --reload-dir /build/src \
    --log-level "${LOG_LEVEL_LOWER}"
