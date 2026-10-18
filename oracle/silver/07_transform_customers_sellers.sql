-- ============================================================
-- ETAPE 4.8
-- CUSTOMERS + SELLERS
-- ============================================================


-- ============================================================
-- 0. NETTOYAGE POUR RENDRE LE SCRIPT RELANCABLE
-- ============================================================

DELETE FROM SILVER.CUSTOMERS;
DELETE FROM SILVER.SELLERS;

DELETE FROM SILVER.REJECTED_ROWS
WHERE SOURCE_TABLE IN (
    'CUSTOMERS_RAW',
    'SELLERS_RAW'
);

COMMIT;


-- ============================================================
-- 1. CUSTOMERS
-- ============================================================

INSERT INTO SILVER.CUSTOMERS (
    CUSTOMER_ID,
    CUSTOMER_UNIQUE_ID,
    CUSTOMER_ZIP_CODE_PREFIX,
    CUSTOMER_CITY,
    CUSTOMER_STATE,
    SOURCE_BATCH_ID
)
SELECT
    TRIM(CUSTOMER_ID),
    TRIM(CUSTOMER_UNIQUE_ID),
    CUSTOMER_ZIP_CODE_PREFIX,
    LOWER(TRIM(CUSTOMER_CITY)),
    UPPER(TRIM(CUSTOMER_STATE)),
    BATCH_ID
FROM BRONZE.CUSTOMERS_RAW;

COMMIT;


-- ============================================================
-- 2. SELLERS
-- ============================================================

INSERT INTO SILVER.SELLERS (
    SELLER_ID,
    SELLER_ZIP_CODE_PREFIX,
    SELLER_CITY,
    SELLER_STATE,
    SOURCE_BATCH_ID
)
SELECT
    TRIM(SELLER_ID),
    SELLER_ZIP_CODE_PREFIX,
    LOWER(TRIM(SELLER_CITY)),
    UPPER(TRIM(SELLER_STATE)),
    BATCH_ID
FROM BRONZE.SELLERS_RAW;

COMMIT;


-- ============================================================
-- 3. VERIFICATION VOLUMES
-- ============================================================

SELECT
    COUNT(*) AS SILVER_CUSTOMERS
FROM SILVER.CUSTOMERS;


SELECT
    COUNT(*) AS SILVER_SELLERS
FROM SILVER.SELLERS;


-- ============================================================
-- 4. CLIENTS SANS GEOLOCALISATION
-- Information de qualité uniquement, pas de rejet.
-- ============================================================

SELECT
    COUNT(DISTINCT C.CUSTOMER_ZIP_CODE_PREFIX)
        AS ZIP_CLIENTS_SANS_GEO
FROM SILVER.CUSTOMERS C

WHERE NOT EXISTS (
    SELECT 1
    FROM BRONZE.GEOLOCATION_RAW G
    WHERE G.GEOLOCATION_ZIP_CODE_PREFIX =
          C.CUSTOMER_ZIP_CODE_PREFIX
);


-- ============================================================
-- 5. VENDEURS SANS GEOLOCALISATION
-- ================