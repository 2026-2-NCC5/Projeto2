#!/bin/sh
# =============================================================================
# ASA Connect+ — Restauração PostgreSQL (Entrega 2)
# Uso: ./scripts/restore.sh <arquivo_backup.sql.gz>
# =============================================================================
set -e

BACKUP_FILE="${1}"

if [ -z "${BACKUP_FILE}" ]; then
  echo "Erro: informe o arquivo de backup."
  echo "Uso: $0 <backup.sql.gz>"
  echo ""
  echo "Backups disponíveis:"
  ls -lh /backups/asaconnect_*.sql.gz 2>/dev/null || echo "(nenhum)"
  exit 1
fi

if [ ! -f "${BACKUP_FILE}" ]; then
  echo "Arquivo não encontrado: ${BACKUP_FILE}"
  exit 1
fi

echo "=== ASA Connect+ — Restauração PostgreSQL ==="
echo "Arquivo: ${BACKUP_FILE}"
echo "Banco  : ${POSTGRES_DB:-asaconnect_db}@postgres"
echo ""
echo "ATENCAO: Esta operação SOBRESCREVE o banco atual!"
printf "Confirmar? [s/N] "
read CONFIRM

if [ "${CONFIRM}" != "s" ] && [ "${CONFIRM}" != "S" ]; then
  echo "Restauração cancelada."
  exit 0
fi

echo "Restaurando..."
gunzip -c "${BACKUP_FILE}" | psql \
  -h postgres \
  -U "${POSTGRES_USER:-asaconnect}" \
  -d "${POSTGRES_DB:-asaconnect_db}" \
  --no-password

echo ""
echo "=== Restauração concluída com sucesso! ==="

