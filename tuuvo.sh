#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"
COMMAND="${1:-help}"

log(){ printf '\n[Tuuvo] %s\n' "$*"; }
warn(){ printf '\n[Tuuvo][ATENÇÃO] %s\n' "$*" >&2; }
fail(){ printf '\n[Tuuvo][ERRO] %s\n' "$*" >&2; exit 1; }

wait_health(){
  log "Aguardando serviço ficar saudável..."
  for _ in $(seq 1 30); do
    if curl -fsS --max-time 5 "http://127.0.0.1:3300/health" >/dev/null 2>&1; then
      log "Serviço tuuvo-site respondeu com sucesso em http://127.0.0.1:3300/health"
      return 0
    fi
    sleep 2
  done
  docker compose logs --tail=40 web >&2 || true
  fail "O serviço tuuvo-site não respondeu ao healthcheck no tempo esperado."
}

deploy(){
  log "Iniciando implantação do Tuuvo Institucional (/opt/tuuvo/site)"
  if docker image inspect tuuvo-site:current >/dev/null 2>&1; then
    log "Registrando versão anterior como tuuvo-site:previous para rollback"
    docker tag tuuvo-site:current tuuvo-site:previous
  fi

  log "Construindo e iniciando container"
  docker compose build web
  docker compose up -d web

  log "Conectando rede tuuvo_site_internal ao proxy Caddy"
  docker network connect tuuvo_site_internal caddy_global 2>/dev/null || true

  wait_health
  log "Deploy do Tuuvo concluído com sucesso!"
}

rollback(){
  log "Iniciando rollback para a versão estável anterior..."
  docker image inspect tuuvo-site:previous >/dev/null 2>&1 || fail "Nenhuma imagem tuuvo-site:previous disponível para rollback."
  docker tag tuuvo-site:current "tuuvo-site:failed-$(date -u +%Y%m%dT%H%M%SZ)"
  docker tag tuuvo-site:previous tuuvo-site:current
  docker compose up -d --no-build web
  wait_health
  log "Rollback do Tuuvo concluído com sucesso!"
}

status(){
  log "Status dos serviços Tuuvo:"
  docker compose ps
  echo
  log "Checagem de rota local:"
  curl -fsS --max-time 5 "http://127.0.0.1:3300/health" || warn "Healthcheck local falhou"
  echo
}

case "$COMMAND" in
  install|update) deploy ;;
  rollback) rollback ;;
  status) status ;;
  logs) docker compose logs --tail=100 -f web ;;
  *)
    cat <<'HELP'
Tuuvo Site Management Script

Uso:
  ./tuuvo.sh install    - Constrói e implanta o site institucional
  ./tuuvo.sh rollback   - Reverte para a versão estável anterior
  ./tuuvo.sh status     - Exibe o estado e saúde do serviço
  ./tuuvo.sh logs       - Acompanha os logs em tempo real
HELP
    ;;
esac
