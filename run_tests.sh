#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
export DAY1_SALT="${DAY1_SALT:-module1-test-salt}"
export JWT_SECRET="${JWT_SECRET:-replace-for-local-development}"

node --test --test-concurrency=1 \
  tests/canonical.test.js \
  tests/validation.test.js \
  backend/test/canonical.test.js \
  backend/test/sports.test.js \
  backend/test/reset.test.js \
  backend/test/scoring.unit.test.js \
  backend/test/standings.unit.test.js \
  backend/test/store.unit.test.js \
  backend/test/rbac.unit.test.js

if ! curl -sf http://127.0.0.1:8080/health >/dev/null; then
  echo "GET /health is not ready on port 8080." >&2
  echo "Start the stack first: DAY1_SALT=demo-salt docker compose up -d --build" >&2
  exit 1
fi

node --test --test-concurrency=1 \
  tests/http.test.js \
  backend/test/http.integration.test.js \
  backend/test/module2.http.test.js \
  backend/test/module3.http.test.js \
  backend/test/module4.http.test.js \
  backend/test/module5.http.test.js
