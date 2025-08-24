# RUN ./localrun/start-all.sh FROM PROJECT ROOT TO START ALL SERVICES

#!/usr/bin/env bash
set -Eeuo pipefail

# ── COMMON ENV ────────────────────────────────────────────────────────────────
export REDIS_HOST=localhost
export REDIS_PORT=6379

export PG_HOST=localhost
export PG_PORT=5432
export PG_USER=postgres
export PG_PASSWORD=postgres
export PG_DATABASE=postgres

# Apps ports
export RESULT_PORT=8081   # Node.js (result)
export VOTE_PORT=8080     # Python (vote)

mkdir -p logs pids

# ── Helpers ───────────────────────────────────────────────────────────────────
require_docker() {
  if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
  fi
}

ensure_container_running() {
  local name="$1"; shift
  if docker ps -a --format '{{.Names}}' | grep -w "$name" >/dev/null; then
    if [ "$(docker inspect -f '{{.State.Running}}' "$name")" != "true" ]; then
      echo "▶️ Starting existing container $name..."
      docker start "$name" >/dev/null
    else
      echo "✔️ Container $name is already running"
    fi
  else
    echo "🐳 Creating and starting container $name..."
    docker run -d --name "$name" "$@" >/dev/null
  fi
}

wait_for_redis() {
  echo "⏳ Waiting for Redis at ${REDIS_HOST}:${REDIS_PORT}..."
  until docker exec redis redis-cli ping >/dev/null 2>&1; do sleep 1; done
  echo "🟥 Redis OK"
}

wait_for_postgres() {
  echo "⏳ Waiting for Postgres at ${PG_HOST}:${PG_PORT}..."
  until docker exec db pg_isready -U "${PG_USER}" >/dev/null 2>&1; do sleep 1; done
  echo "🐘 Postgres OK"
}

start_node_result() {
  echo "🟩 Starting Result (Node.js) at :${RESULT_PORT}..."
  pushd result >/dev/null
  if [ ! -d node_modules ]; then
    npm install --silent
  fi
  PORT="${RESULT_PORT}" \
  PG_HOST="${PG_HOST}" PG_PORT="${PG_PORT}" \
  PG_USER="${PG_USER}" PG_PASSWORD="${PG_PASSWORD}" PG_DATABASE="${PG_DATABASE}" \
  nohup node server.js >> ../logs/result.log 2>&1 & echo $! > ../pids/result.pid
  popd >/dev/null
  echo "   → http://localhost:${RESULT_PORT}"
}

start_python_vote() {
  echo "🐍 Starting Vote (Flask) at :${VOTE_PORT}..."
  pushd vote >/dev/null
  PORT="${VOTE_PORT}" \
  REDIS_HOST="${REDIS_HOST}" REDIS_PORT="${REDIS_PORT}" \
  nohup python3 app.py >> ../logs/vote.log 2>&1 & echo $! > ../pids/vote.pid
  popd >/dev/null
  echo "   → http://localhost:${VOTE_PORT}"
}

start_worker() {
  echo "⚙️ Starting Worker (.NET)..."
  pushd worker >/dev/null
  DB_HOST="${PG_HOST}" REDIS_HOST="${REDIS_HOST}" \
  nohup dotnet run >> ../logs/worker.log 2>&1 & echo $! > ../pids/worker.pid
  popd >/dev/null
}

# ── RUN ───────────────────────────────────────────────────────────────────────
require_docker

echo "🔴 [1/4] Redis"
ensure_container_running redis -p 6379:6379 redis:7-alpine
wait_for_redis

echo "🐘 [2/4] Postgres"
ensure_container_running db -e POSTGRES_USER="${PG_USER}" -e POSTGRES_PASSWORD="${PG_PASSWORD}" -p 5432:5432 postgres:15-alpine
wait_for_postgres

echo "🟩 [3/4] Result (Node.js)"
start_node_result

echo "🐍 [4/4] Vote (Python/Flask)"
start_python_vote

echo "⚙️ [5/5] Worker (.NET)"
start_worker

echo ""
echo "✅ All Running! - Endpoints:"
echo "   Vote   → http://localhost:${VOTE_PORT}"
echo "   Result → http://localhost:${RESULT_PORT}"
echo ""
echo "📌 Important: Worker (.NET) moves votes from Redis → Postgres."
