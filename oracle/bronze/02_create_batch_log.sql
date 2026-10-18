-- ============================================================
-- MODERN DATA PLATFORM - OLIST
-- ETAPE 3.2
-- TABLE DE SUIVI DES BATCHES D'INGESTION
-- ============================================================

ALTER SESSION SET CURRENT_SCHEMA = BRONZE;


-- ============================================================
-- TABLE BATCH_LOG
-- Une ligne = une exécution de chargement d'une source
-- ============================================================

CREATE TABLE BATCH_LOG (

    BATCH_ID        VARCHAR2(100) PRIMARY KEY,

    BATCH_DATE      DATE NOT NULL,

    SOURCE_NAME     VARCHAR2(255) NOT NULL,

    TARGET_TABLE    VARCHAR2(128) NOT NULL,

    STARTED_AT      TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,

    FINISHED_AT     TIMESTAMP,

    ROWS_READ       NUMBER DEFAULT 0 NOT NULL,

    ROWS_INSERTED   NUMBER DEFAULT 0 NOT NULL,

    STATUS          VARCHAR2(20) NOT NULL,

    ERROR_MESSAGE   VARCHAR2(4000),

    CONSTRAINT CK_BATCH_LOG_STATUS
        CHECK (
            STATUS IN (
                'RUNNING',
                'SUCCESS',
                'FAILED'
            )
        )
);


-- ============================================================
-- VERIFICATION
-- ============================================================

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    NULLABLE
FROM ALL_TAB_COLUMNS
WHERE OWNER = 'BRONZE'
  AND TABLE_NAME = 'BATCH_LOG'
ORDER BY COLUMN_ID;