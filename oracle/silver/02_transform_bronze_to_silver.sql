-- ============================================================
-- MODERN DATA PLATFORM - OLIST
-- ETAPE 4.3
-- TRANSFORMATION BRONZE.ORDERS_RAW -> SILVER.ORDERS
-- ============================================================


-- ============================================================
-- 0. NETTOYAGE DU TEST
--
-- Permet de relancer ce script sans dupliquer les résultats.
-- On ne touche jamais à BRONZE.
-- ============================================================

DELETE FROM SILVER.ORDERS;

DELETE FROM SILVER.REJECTED_ROWS
WHERE SOURCE_TABLE = 'ORDERS_RAW';

COMMIT;


-- ============================================================
-- 1. ORD_001
--
-- Livraison client antérieure à la remise au transporteur.
-- Ces lignes sont considérées incohérentes.
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
    'ORD001-' || ORDER_ID,

    'ORDERS_RAW',

    ORDER_ID,

    BATCH_ID,

    'ORD_001',

    'Date de livraison client antérieure à la remise au transporteur',

    'order_delivered_customer_date < order_delivered_carrier_date',

    'order_id=' || ORDER_ID
        || '; status=' || ORDER_STATUS
        || '; carrier_date='
        || NVL(
            ORDER_DELIVERED_CARRIER_DATE,
            'NULL'
        )
        || '; customer_date='
        || NVL(
            ORDER_DELIVERED_CUSTOMER_DATE,
            'NULL'
        )

FROM BRONZE.ORDERS_RAW

WHERE
    ORDER_DELIVERED_CUSTOMER_DATE IS NOT NULL
    AND ORDER_DELIVERED_CARRIER_DATE IS NOT NULL

    AND TO_TIMESTAMP(
        ORDER_DELIVERED_CUSTOMER_DATE,
        'YYYY-MM-DD HH24:MI:SS'
    )
    <
    TO_TIMESTAMP(
        ORDER_DELIVERED_CARRIER_DATE,
        'YYYY-MM-DD HH24:MI:SS'
    );


-- ============================================================
-- 2. ORD_002
--
-- Commande marquée DELIVERED sans date de livraison client.
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
    'ORD002-' || ORDER_ID,

    'ORDERS_RAW',

    ORDER_ID,

    BATCH_ID,

    'ORD_002',

    'Commande delivered sans date de livraison client',

    'order_status = delivered et order_delivered_customer_date IS NULL',

    'order_id=' || ORDER_ID
        || '; status=' || ORDER_STATUS
        || '; customer_date=NULL'

FROM BRONZE.ORDERS_RAW

WHERE
    LOWER(TRIM(ORDER_STATUS)) = 'delivered'

    AND ORDER_DELIVERED_CUSTOMER_DATE IS NULL;


-- ============================================================
-- 3. ORD_003
--
-- Date d'approbation antérieure à la date d'achat.
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
    'ORD003-' || ORDER_ID,

    'ORDERS_RAW',

    ORDER_ID,

    BATCH_ID,

    'ORD_003',

    'Date approbation antérieure à la date achat',

    'order_approved_at < order_purchase_timestamp',

    'order_id=' || ORDER_ID
        || '; purchase='
        || NVL(
            ORDER_PURCHASE_TIMESTAMP,
            'NULL'
        )
        || '; approved='
        || NVL(
            ORDER_APPROVED_AT,
            'NULL'
        )

FROM BRONZE.ORDERS_RAW

WHERE
    ORDER_APPROVED_AT IS NOT NULL
    AND ORDER_PURCHASE_TIMESTAMP IS NOT NULL

    AND TO_TIMESTAMP(
        ORDER_APPROVED_AT,
        'YYYY-MM-DD HH24:MI:SS'
    )
    <
    TO_TIMESTAMP(
        ORDER_PURCHASE_TIMESTAMP,
        'YYYY-MM-DD HH24:MI:SS'
    );


-- ============================================================
-- 4. INSERTION DES COMMANDES VALIDES DANS SILVER
--
-- Une commande est insérée seulement si elle n'apparaît dans
-- aucun rejet critique ORD_001 / ORD_002 / ORD_003.
-- ============================================================

INSERT INTO SILVER.ORDERS (
    ORDER_ID,
    CUSTOMER_ID,
    ORDER_STATUS,

    ORDER_PURCHASE_TIMESTAMP,
    ORDER_APPROVED_AT,
    ORDER_DELIVERED_CARRIER_DATE,
    ORDER_DELIVERED_CUSTOMER_DATE,
    ORDER_ESTIMATED_DELIVERY_DATE,

    SOURCE_BATCH_ID
)
SELECT
    B.ORDER_ID,

    B.CUSTOMER_ID,

    LOWER(TRIM(B.ORDER_STATUS)),

    TO_TIMESTAMP(
        B.ORDER_PURCHASE_TIMESTAMP,
        'YYYY-MM-DD HH24:MI:SS'
    ),

    CASE
        WHEN B.ORDER_APPROVED_AT IS NOT NULL
        THEN TO_TIMESTAMP(
            B.ORDER_APPROVED_AT,
            'YYYY-MM-DD HH24:MI:SS'
        )
    END,

    CASE
        WHEN B.ORDER_DELIVERED_CARRIER_DATE IS NOT NULL
        THEN TO_TIMESTAMP(
            B.ORDER_DELIVERED_CARRIER_DATE,
            'YYYY-MM-DD HH24:MI:SS'
        )
    END,

    CASE
        WHEN B.ORDER_DELIVERED_CUSTOMER_DATE IS NOT NULL
        THEN TO_TIMESTAMP(
            B.ORDER_DELIVERED_CUSTOMER_DATE,
            'YYYY-MM-DD HH24:MI:SS'
        )
    END,

    CASE
        WHEN B.ORDER_ESTIMATED_DELIVERY_DATE IS NOT NULL
        THEN TO_TIMESTAMP(
            B.ORDER_ESTIMATED_DELIVERY_DATE,
            'YYYY-MM-DD HH24:MI:SS'
        )
    END,

    B.BATCH_ID

FROM BRONZE.ORDERS_RAW B

WHERE NOT EXISTS (

    SELECT 1

    FROM SILVER.REJECTED_ROWS R

    WHERE R.SOURCE_TABLE = 'ORDERS_RAW'

      AND R.SOURCE_KEY = B.ORDER_ID

      AND R.RULE_CODE IN (
          'ORD_001',
          'ORD_002',
          'ORD_003'
      )
);


COMMIT;


-- ============================================================
-- 5. VERIFICATION DU NOMBRE DE COMMANDES SILVER
-- ============================================================

SELECT
    COUNT(*) AS SILVER_ORDERS
FROM SILVER.ORDERS;


-- ============================================================
-- 6. VERIFICATION DES REJETS
-- ============================================================

SELECT
    RULE_CODE,
    COUNT(*) AS NB_REJETS
FROM SILVER.REJECTED_ROWS
WHERE SOURCE_TABLE = 'ORDERS_RAW'
GROUP BY RULE_CODE
ORDER BY RULE_CODE;


-- ============================================================
-- 7. CONTROLE DE RECONCILIATION
-- ============================================================

SELECT
    (SELECT COUNT(*)
     FROM BRONZE.ORDERS_RAW)
        AS BRONZE_ORDERS,

    (SELECT COUNT(*)
     FROM SILVER.ORDERS)
        AS SILVER_ORDERS,

    (
        SELECT COUNT(DISTINCT SOURCE_KEY)
        FROM SILVER.REJECTED_ROWS
        WHERE SOURCE_TABLE = 'ORDERS_RAW'
    )
        AS ORDERS_REJETEES

FROM DUAL;