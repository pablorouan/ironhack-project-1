# RUN ./localrun/stop-all.sh FROM PROJECT ROOT TO STOP ALL SERVICES

#!/usr/bin/env bash
set -Eeuo pipefail

echo "🛑 Stopping services..."

# Kill local processes if they exist (vote, result, worker)
for svc in vote result worker; do
  if [ -f "pids/$svc.pid" ]; then
    PID=$(cat pids/$svc.pid)
    if ps -p $PID > /dev/null 2>&1; then
      echo "  🔪 Killing $svc (PID $PID)"
      kill $PID || true
    fi
    rm -f pids/$svc.pid
  fi
done

# Detener contenedores Docker
for container in db redis; do
  if docker ps -q -f name=$container > /dev/null; then
    echo "  🐳 Stopping container $container"
    docker stop $container || true
    docker rm $container || true
  fi
done

echo "🧹 Cleaning up ports"
echo "✅ All services stopped"
