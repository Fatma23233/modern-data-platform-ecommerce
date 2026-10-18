-- ============================================================
-- MODERN DATA PLATFORM - OLIST
-- ETAPE 3.4
-- DROITS PIPELINE SUR BRONZE
-- ============================================================


-- ============================================================
-- TABLES RAW
-- PIPELINE doit pouvoir :
-- SELECT : vérifier les données chargées
-- INSERT : charger les lignes
-- DELETE : remplacer un batch pour garantir l'idempotence
-- ============================================================

GRANT SELECT, INSERT, DELETE
ON BRONZE.CUSTOMERS_RAW
TO PIPELINE;

GRANT SELECT, INSERT, DELETE
ON BRONZE.GEOLOCATION_RAW
TO PIPELINE;

GRANT SELECT, INSERT, DELETE
ON BRONZE.ORDER_ITEMS_RAW
TO PIPELINE;

GRANT SELECT, INSERT, DELETE
ON BRONZE.ORDERS_RAW
TO PIPELINE;

GRANT SELECT, INSERT, DELETE
ON BRONZE.PAYMENTS_RAW
TO PIPELINE;

GRANT SELECT, INSERT, DELETE
ON BRONZE.PRODUCTS_RAW
TO PIPELINE;

GRANT SELECT, INSERT, DELETE
ON BRONZE.REVIEWS_RAW
TO PIPELINE;

GRANT SELECT, INSERT, DELETE
ON BRONZE.SELLERS_RAW
TO PIPELINE;

GRANT SELECT, INSERT, DELETE
ON BRONZE.CATEGORY_TRANSLATION_RAW
TO PIPELINE;


-- ============================================================
-- BATCH_LOG
--
-- INSERT : création du suivi
-- UPDATE : RUNNING -> SUCCESS / FAILED
-- SELECT : consultation
-- ============================================================

GRANT SELECT, INSERT, UPDATE
ON BRONZE.BATCH_LOG
TO PIPELINE;


-- ============================================================
-- VERIFICATION
-- ============================================================

SELECT
    GRANTEE,
    OWNER,
    TABLE_NAME,
    PRIVILEGE
FROM DBA_TAB_PRIVS
WHERE GRANTEE = 'PIPELINE'
  AND OWNER = 'BRONZE'
ORDER BY TABLE_NAME, PRIVILEGE;