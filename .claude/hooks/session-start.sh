#!/usr/bin/env bash
# Session start hook: validate environment and DB before working
set -euo pipefail

errors=()

# Check required env vars
for var in ODDS_API_KEY POSTGRES_HOST POSTGRES_USER POSTGRES_PASSWORD; do
  if [ -z "${!var:-}" ]; then
    errors+=("Missing env var: $var")
  fi
done

# Set defaults
export POSTGRES_PORT="${POSTGRES_PORT:-5432}"
export POSTGRES_DB="${POSTGRES_DB:-sports_betting}"

# Check postgres connectivity (if psql available and creds are set)
if command -v psql &>/dev/null && [ -n "${POSTGRES_HOST:-}" ] && [ -n "${POSTGRES_USER:-}" ]; then
  if ! psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT 1" &>/dev/null 2>&1; then
    errors+=("Cannot connect to postgres at $POSTGRES_HOST:$POSTGRES_PORT/$POSTGRES_DB")
  else
    # Check if schema is initialized
    table_count=$(psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAc \
      "SELECT COUNT(*) FROM information_schema.tables WHERE table_name IN ('analysis_runs','picks','results')" 2>/dev/null || echo "0")
    if [ "$table_count" -lt 3 ]; then
      errors+=("Schema not initialized. Run: psql -f schema.sql")
    fi
  fi
fi

# Report
if [ ${#errors[@]} -gt 0 ]; then
  echo "SESSION START WARNINGS:"
  for e in "${errors[@]}"; do
    echo "  - $e"
  done
  exit 0  # warn but don't block
fi

echo "Environment OK. DB connected. Schema verified."
