#!/bin/bash

# Configuration
OTEL_HOST="localhost"
OTLP_HTTP_PORT="4318" # For Metrics and Traces (HTTP)
LOG_UDP_PORT="5140"   # For Logs (UDP) - Ensure your OTel collector has a UDP receiver enabled on this port (e.g., syslog)

# Generate current timestamp in nanoseconds
NOW_NANO=$(($(date +%s) * 1000000000))

# --- Metrics (OTLP HTTP) ---
echo "Sending Metrics to http://${OTEL_HOST}:${OTLP_HTTP_PORT}/v1/metrics..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "http://${OTEL_HOST}:${OTLP_HTTP_PORT}/v1/metrics" \
  -H "Content-Type: application/json" \
  -d "{
  \"resourceMetrics\": [{
    \"resource\": {
      \"attributes\": [{ \"key\": \"service.name\", \"value\": { \"stringValue\": \"bash-script-metrics\" } }]
    },
    \"scopeMetrics\": [{
      \"metrics\": [{
        \"name\": \"sample_metric\",
        \"unit\": \"1\",
        \"gauge\": {
          \"dataPoints\": [{
            \"asInt\": $((1 + RANDOM % 100)),
            \"timeUnixNano\": \"${NOW_NANO}\"
          }]
        }
      }]
    }]
  }]
}")

if [[ "$HTTP_CODE" -eq 200 || "$HTTP_CODE" -eq 202 ]]; then
  echo "Metrics sent successfully (HTTP $HTTP_CODE)."
else
  echo "Failed to send metrics (HTTP $HTTP_CODE)."
fi

# --- Traces (OTLP HTTP) ---
TRACE_ID=$(openssl rand -hex 16)
SPAN_ID=$(openssl rand -hex 8)
echo "Sending Traces to http://${OTEL_HOST}:${OTLP_HTTP_PORT}/v1/traces..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "http://${OTEL_HOST}:${OTLP_HTTP_PORT}/v1/traces" \
  -H "Content-Type: application/json" \
  -d "{
  \"resourceSpans\": [{
    \"resource\": {
      \"attributes\": [{ \"key\": \"service.name\", \"value\": { \"stringValue\": \"bash-script-traces\" } }]
    },
    \"scopeSpans\": [{
      \"spans\": [{
        \"traceId\": \"${TRACE_ID}\",
        \"spanId\": \"${SPAN_ID}\",
        \"name\": \"sample_span\",
        \"kind\": 1,
        \"startTimeUnixNano\": \"${NOW_NANO}\",
        \"endTimeUnixNano\": \"$(($NOW_NANO + 100000))\",
        \"attributes\": [{ \"key\": \"http.method\", \"value\": { \"stringValue\": \"GET\" } }]
      }]
    }]
  }]
}")

if [[ "$HTTP_CODE" -eq 200 || "$HTTP_CODE" -eq 202 ]]; then
  echo "Traces sent successfully (HTTP $HTTP_CODE)."
else
  echo "Failed to send traces (HTTP $HTTP_CODE)."
fi

# --- Logs (UDP) ---
# Sending a simple JSON log via UDP. 
# Note: The OTel collector must be configured with a receiver that accepts UDP (e.g., syslog, fluentforward, or a custom udp receiver).
LOG_MESSAGE="{\"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\", \"level\": \"INFO\", \"message\": \"This is a sample log via UDP\", \"service\": \"bash-script-logs\"}"

echo "Sending Logs to udp://${OTEL_HOST}:${LOG_UDP_PORT}..."
if echo -n "$LOG_MESSAGE" | nc -u -w 1 "${OTEL_HOST}" "${LOG_UDP_PORT}"; then
  echo "Logs sent (UDP)."
else
  echo "Failed to send logs (UDP)."
fi
