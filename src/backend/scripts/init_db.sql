-- =============================================================================
-- ASA Connect+ — Init PostgreSQL (Entrega 2)
-- Executado automaticamente na primeira inicialização do container
-- =============================================================================

-- Extensão UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Log de operações de backup/restore
CREATE TABLE IF NOT EXISTS backup_log (
    id SERIAL PRIMARY KEY,
    operation VARCHAR(20) NOT NULL,
    filename VARCHAR(255),
    status VARCHAR(20) NOT NULL,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE backup_log IS 'Registro de operações de backup e restauração';

