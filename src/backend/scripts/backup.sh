#!/bin/sh
# =============================================================================
# ASA Connect+ — Backup PostgreSQL (Entrega 2)
# Uso: docker compose -f docker-compose.prod.yml --profile backup run --rm backup
# Agenda sugerida (crontab no host): 0 2 * * * <comando acima>
# =============================================================================
set -e

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="/backups/asaconnect_${TIMESTAMP}.sql.gz"
RETENTION_DAYS=7

echo "=== ASA Connect+ — Backup PostgreSQL ==="
echo "Timestamp : ${TIMESTAMP}"
echo "Destino   : ${BACKUP_FILE}"
echo ""

pg_dump \
  -h postgres \
  -U "${POSTGRES_USER:-asaconnect}" \
  -d "${POSTGRES_DB:-asaconnect_db}" \
  --no-password \
  --format=plain \
  --clean \
  --if-exists \
  | gzip > "${BACKUP_FILE}"

BACKUP_SIZE=$(du -sh "${BACKUP_FILE}" | cut -f1)
echo "OK Backup criado: ${BACKUP_FILE} (${BACKUP_SIZE})"

# Remove backups antigos
find /backups -name "asaconnect_*.sql.gz" -mtime +${RETENTION_DAYS} -delete
echo "OK Backups com mais de ${RETENTION_DAYS} dias removidos."

echo ""
echo "=== Backups disponíveis ==="
ls -lh /backups/asaconnect_*.sql.gz 2>/dev/null || echo "(nenhum)"
echo "==========================="

