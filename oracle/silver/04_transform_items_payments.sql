-- ============================================================
-- MODERN DATA PLATFORM - OLIST
-- ETAPE 4.5
-- TRANSFORMATION ORDER_ITEMS + PAYMENTS
-- ============================================================


-- ============================================================
-- 0. NETTOYAGE POUR RENDRE LE SCRIPT RELANCABLE
-- ============================================================

DELETE FROM SILVER.ORDER_ITEMS;
DELETE FROM SILVER.PAYMENTS;

DELETE FROM SILVER.REJECTED_ROWS
WHERE SOURCE_TABLE IN (
    'ORDER_ITEMS_RAW',
    'PAYMENTS_RAW'
);

COMMIT;


-- ============================================================
-- PARTIE A : ORDER_ITEMS
-- ============================================================


-- ============================================================
-- ITEM_001
-- PRIX NULL, NUL OU NEGATIF
-- ============================================================

INSERT INTO SILVER.REJECTED_ROWS (
    REJECT_ID,
    SOURCE_TABLE,
    SOURCE_KEY,
    SOURCE_BATCH_ID,
    RULE_CODE,
    RULE_DESCRIPTION,
    REJECT_REASON,
    RAW_DATA
)
SELECT
    'ITEM001-' || ORDER_ID || '-' || ORDER_ITEM_ID,

    'ORDER_ITEMS_RAW',

    ORDER_ID || '-' || ORDER_ITEM_ID,

    BATCH_ID,

    'ITEM_001',

    'Prix article NULL, nul ou négatif',

    'price IS NULL OR price <= 0',

    'order_id=' || ORDER_ID
        || '; order_item_id=' || ORDER_ITEM_ID
        || '; product_id=' || PRODUCT_ID
        || '; price=' || NVL(TO_CHAR(PRICE), 'NULL')

FROM BRONZE.ORDER_ITEMS_RAW

WHERE PRICE IS NULL
   OR PRICE <= 0;


-- ============================================================
-- ITEM_002
-- FRET NULL OU NEGATIF
-- ============================================================

INSERT INTO SILVER.REJECTED_ROWS (
    REJECT_ID,
    SOURCE_TABLE,
    SOURCE_KEY,
    SOURCE_BATCH_ID,
    RULE_CODE,
    RULE_DESCRIPTION,
    REJECT_REASON,
    RAW_DATA
)
SELECT
    'ITEM002-' || ORDER_ID || '-' || ORDER_ITEM_ID,

    'ORDER_ITEMS_RAW',

    ORDER_ID || '-' || ORDER_ITEM_ID,

    BATCH_ID,

    'ITEM_002',

    'Valeur de fret NULL ou négative',

    'freight_value IS NULL OR freight_value < 0',

    'order_id=' || ORDER_ID
        || '; order_item_id=' || ORDER_ITEM_ID
        || '; freight_value='
        || NVL(TO_CHAR(FREIGHT_VALUE), 'NULL')

FROM BRONZE.ORDER_ITEMS_RAW

WHERE FREIGHT_VALUE IS NULL
   OR FREIGHT_VALUE < 0;


-- ============================================================
-- INSERTION DES ORDER_ITEMS VALIDES
-- ============================================================

INSERT INTO SILVER.ORDER_ITEMS (
    ORDER_ID,
    ORDER_ITEM_ID,
    PRODUCT_ID,
    SELLER_ID,
    SHIPPING_LIMIT_DATE,
    PRICE,
    FREIGHT_VALUE,
    SOURCE_BATCH_ID
)
SELECT
    B.ORDER_ID,
    B.ORDER_ITEM_ID,
    B.PRODUCT_ID,
    B.SELLER_ID,

    CASE
        WHEN B.SHIPPING_LIMIT_DATE IS NOT NULL
        THEN TO_TIMESTAMP(
            B.SHIPPING_LIMIT_DATE,
            'YYYY-MM-DD HH24:MI:SS'
        )
    END,

    B.PRICE,
    B.FREIGHT_VALUE,
    B.BATCH_ID

FROM BRONZE.ORDER_ITEMS_RAW B

WHERE NOT EXISTS (
    SELECT 1
    FROM SILVER.REJECTED_ROWS R

    WHERE R.SOURCE_TABLE = 'ORDER_ITEMS_RAW'

      AND R.SOURCE_KEY =
          B.ORDER_ID || '-' || B.ORDER_ITEM_ID

      AND R.RULE_CODE IN (
          'ITEM_001',
          'ITEM_002'
      )
);


-- ============================================================
-- PARTIE B : PAYMENTS
-- ============================================================


-- ============================================================
-- PAY_001
-- MONTANT NULL OU NEGATIF
-- ============================================================

INSERT INTO SILVER.REJECTED_ROWS (
    REJECT_ID,
    SOURCE_TABLE,
    SOURCE_KEY,
    SOURCE_BATCH_ID,
    RULE_CODE,
    RULE_DESCRIPTION,
    REJECT_REASON,
    RAW_DATA
)
SELECT
    'PAY001-' || ORDER_ID || '-' || PAYMENT_SEQUENTIAL,

    'PAYMENTS_RAW',

    ORDER_ID || '-' || PAYMENT_SEQUENTIAL,

    BATCH_ID,

    'PAY_001',

    'Montant du paiement NULL ou négatif',

    'payment_value IS NULL OR payment_value < 0',

    'order_id=' || ORDER_ID
        || '; payment_sequential=' || PAYMENT_SEQUENTIAL
        || '; payment_type=' || NVL(PAYMENT_TYPE, 'NULL')
        || '; payment_value='
        || NVL(TO_CHAR(PAYMENT_VALUE), 'NULL')

FROM BRONZE.PAYMENTS_RAW

WHERE PAYMENT_VALUE IS NULL
   OR PAYMENT_VALUE < 0;


-- ============================================================
-- PAY_002
-- NOMBRE DE MENSUALITES NULL OU NEGATIF
-- ============================================================

INSERT INTO SILVER.REJECTED_ROWS (
    REJECT_ID,
    SOURCE_TABLE,
    SOURCE_KEY,
    SOURCE_BATCH_ID,
    RULE_CODE,
    RULE_DESCRIPTION,
    REJECT_REASON,
    RAW_DATA
)
SELECT
    'PAY002-' || ORDER_ID || '-' || PAYMENT_SEQUENTIAL,

    'PAYMENTS_RAW',

    ORDER_ID || '-' || PAYMENT_SEQUENTIAL,

    BATCH_ID,

    'PAY_002',

    'Nombre de mensualités NULL ou négatif',

    'payment_installments IS NULL OR payment_installments < 0',

    'order_id=' || ORDER_ID
        || '; payment_sequential=' || PAYMENT_SEQUENTIAL
        || '; installments='
        || NVL(TO_CHAR(PAYMENT_INSTALLMENTS), 'NULL')

FROM BRONZE.PAYMENTS_RAW

WHERE PAYMENT_INSTALLMENTS IS NULL
   OR PAYMENT_INSTALLMENTS < 0;


-- ============================================================
-- INSERTION DES PAYMENTS VALIDES
-- ============================================================

INSERT INTO SILVER.PAYMENTS (
    ORDER_ID,
    PAYMENT_SEQUENTIAL,
    PAYMENT_TYPE,
    PAYMENT_INSTALLMENTS,
    PAYMENT_VALUE,
    SOURCE_BATCH_ID
)
SELECT
    B.ORDER_ID,
    B.PAYMENT_SEQUENTIAL,
    LOWER(TRIM(B.PAYMENT_TYPE)),
    B.PAYMENT_INSTALLMENTS,
    B.PAYMENT_VALUE,
    B.BATCH_ID

FROM BRONZE.PAYMENTS_RAW B

WHERE NOT EXISTS (
    SELECT 1
    FROM SILVER.REJECTED_ROWS R

    WHERE R.SOURCE_TABLE = 'PAYMENTS_RAW'

      AND R.SOURCE_KEY =
          B.ORDER_ID || '-' || B.PAYMENT_SEQUENTIAL

      AND R.RULE_CODE IN (
          'PAY_001',
          'PAY_002'
      )
);


COMMIT;


-- ============================================================
-- 1. VOLUMES SILVER
-- ============================================================

SELECT COUNT(*) AS SILVER_ORDER_ITEMS
FROM SILVER.ORDER_ITEMS;


SELECT COUNT(*) AS SILVER_PAYMENTS
FROM SILVER.PAYMENTS;


-- ============================================================
-- 2. REJETS
-- ============================================================

SELECT
    SOURCE_TABLE,
    RULE_CODE,
    COUNT(*) AS NB_REJETS
FROM SILVER.REJECTED_ROWS
WHERE SOURCE_TABLE IN (
    'ORDER_ITEMS_RAW',
    'PAYMENTS_RAW'
)
GROUP BY
    SOURCE_TABLE,
    RULE_CODE
ORDER BY
    SOURCE_TABLE,
    RULE_CODE;


-- ============================================================
-- 3. RECONCILIATION ORDER_ITEMS
-- ============================================================

SELECT
    (
        SELECT COUNT(*)
        FROM BRONZE.ORDER_ITEMS_RAW
    ) AS BRONZE_ITEMS,

    (
        SELECT COUNT(*)
        FROM SILVER.ORDER_ITEMS
    ) AS SILVER_ITEMS,

    (
        SELECT COUNT(DISTINCT SOURCE_KEY)
        FROM SILVER.REJECTED_ROWS
        WHERE SOURCE_TABLE = 'ORDER_ITEMS_RAW'
    ) AS ITEMS_REJETES

FROM DUAL;


-- ============================================================
-- 4. RECONCILIATION PAYMENTS
-- ============================================================

SELECT
    (
        SELECT COUNT(*)
        FROM BRONZE.PAYMENTS_RAW
    ) AS BRONZE_PAYMENTS,

    (
        SELECT COUNT(*)
        FROM SILVER.PAYMENTS
    ) AS SILVER_PAYMENTS,

    (
        SELECT COUNT(DISTINCT SOURCE_KEY)
        FROM SILVER.REJECTED_ROWS
        WHERE SOURCE_TABLE = 'PAYMENTS_RAW'
    ) AS PAYMENTS_REJETES

FROM DUAL;