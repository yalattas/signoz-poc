#!/bin/sh

# Multi-entrypoint startup script
# Usage: ./bootup.sh [web|queue|cron]
# Default: web (API server)

# Get the entrypoint argument (default to 'web' if not provided)
ENTRYPOINT=${1:-web}
OTEL_ENABLED=${OTEL_ENABLED:-"false"}

# Common signal handling
trap 'sleep 20' SIGTERM SIGINT

# Function to run database migrations and static files collection
setup_django() {
    echo "Running Django setup..."
    python manage.py migrate --no-input
    python manage.py collectstatic --no-input
}

case "$ENTRYPOINT" in
    web)
        echo "Starting Django API server..."
        setup_django
        if [ "$OTEL_ENABLED" = "true" ]; then
            echo "OTEL is enabled. Starting with OpenTelemetry instrumentation..."
            opentelemetry-instrument uvicorn conf.asgi:application --host "0.0.0.0" --port 8000
        else
            uvicorn conf.asgi:application --host "0.0.0.0" --port 8000
        fi
        ;;
    queue)
        echo "Starting Celery worker..."
        celery -A conf.celery:app worker -E -l INFO -n $REDIS_PREFIX
        ;;
    cron)
        echo "Starting Celery beat scheduler..."
        celery -A conf.celery:app beat --loglevel=INFO
        ;;
    *)
        echo "Invalid entrypoint: $ENTRYPOINT"
        echo "Usage: $0 [web|queue|cron]"
        echo "  web   - Start Django API server (default)"
        echo "  queue - Start Celery worker"
        echo "  cron  - Start Celery beat scheduler"
        exit 1
        ;;
esac