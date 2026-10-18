-- ============================================================
-- MODERN DATA PLATFORM - OLIST
-- GOLD
-- 11_audit_gold.sql
--
-- AUDIT GLOBAL DE LA COUCHE GOLD
--
-- Tables auditees :
--
-- DIM_DATE
-- DIM_GEOGRAPHY
-- DIM_CUSTOMER
-- DIM_PRODUCT
-- DIM_SELLER
--
-- FACT_ORDERS
-- FACT_ORDER_ITEMS
-- FACT_PAYMENTS
-- FACT_REVIEWS
--
-- Ce script ne modifie aucune donnee.
-- Il effectue uniquement des controles.
-- ============================================================


-- ============================================================
-- 1. VOLUMES DE TOUTES LES TABLES GOLD
-- ============================================================

SELECT 'DIM_DATE' AS TABLE_NAME, COUNT(*) AS NB_ROWS
FROM GOLD.DIM_DATE

UNION ALL

SELECT 'DIM_GEOGRAPHY', COUNT(*)
FROM GOLD.DIM_GEOGRAPHY

UNION ALL

SELECT 'DIM_CUSTOMER', COUNT(*)
FROM GOLD.DIM_CUSTOMER

UNION ALL

SELECT 'DIM_PRODUCT', COUNT(*)
FROM GOLD.DIM_PRODUCT

UNION ALL

SELECT 'DIM_SELLER', COUNT(*)
FROM GOLD.DIM_SELLER

UNION ALL

SELECT 'FACT_ORDERS', COUNT(*)
FROM GOLD.FACT_ORDERS

UNION ALL

SELECT 'FACT_ORDER_ITEMS', COUNT(*)
FROM GOLD.FACT_ORDER_ITEMS

UNION ALL

SELECT 'FACT_PAYMENTS', COUNT(*)
FROM GOLD.FACT_PAYMENTS

UNION ALL

SELECT 'FACT_REVIEWS', COUNT(*)
FROM GOLD.FACT_REVIEWS

ORDER BY TABLE_NAME;


-- ============================================================
-- VOLUMES ATTENDUS DEJA VALIDES
--
-- DIM_DATE                800
-- DIM_GEOGRAPHY        19 016
-- DIM_CUSTOMER         99 441
-- DIM_PRODUCT          32 947
-- DIM_SELLER            3 095
--
-- FACT_ORDERS          99 410
-- FACT_ORDER_ITEMS    112 584
-- FACT_PAYMENTS       103 852
-- FACT_REVIEWS         99 193
-- ============================================================



-- ============================================================
-- 2. AUDIT DES CLES DES DIMENSIONS
--
-- Pour chaque dimension :
-- TOTAL doit etre egal au nombre de cles distinctes.
-- ============================================================

SELECT
    'DIM_DATE' AS TABLE_NAME,
    COUNT(*) AS TOTAL_ROWS,
    COUNT(DISTINCT DATE_KEY) AS DISTINCT_KEYS,
    COUNT(*) - COUNT(DISTINCT DATE_KEY) AS DUPLICATES
FROM GOLD.DIM_DATE

UNION ALL

SELECT
    'DIM_GEOGRAPHY',
    COUNT(*),
    COUNT(DISTINCT GEOGRAPHY_KEY),
    COUNT(*) - COUNT(DISTINCT GEOGRAPHY_KEY)
FROM GOLD.DIM_GEOGRAPHY

UNION ALL

SELECT
    'DIM_CUSTOMER',
    COUNT(*),
    COUNT(DISTINCT CUSTOMER_KEY),
    COUNT(*) - COUNT(DISTINCT CUSTOMER_KEY)
FROM GOLD.DIM_CUSTOMER

UNION ALL

SELECT
    'DIM_PRODUCT',
    COUNT(*),
    COUNT(DISTINCT PRODUCT_KEY),
    COUNT(*) - COUNT(DISTINCT PRODUCT_KEY)
FROM GOLD.DIM_PRODUCT

UNION ALL

SELECT
    'DIM_SELLER',
    COUNT(*),
    COUNT(DISTINCT SELLER_KEY),
    COUNT(*) - COUNT(DISTINCT SELLER_KEY)
FROM GOLD.DIM_SELLER

ORDER BY TABLE_NAME;


-- ============================================================
-- 3. AUDIT DES CLES METIER DES DIMENSIONS
-- ============================================================

SELECT
    'DIM_CUSTOMER' AS TABLE_NAME,
    COUNT(*) AS TOTAL_ROWS,
    COUNT(DISTINCT CUSTOMER_ID) AS DISTINCT_BUSINESS_KEYS,
    COUNT(*) - COUNT(DISTINCT CUSTOMER_ID) AS DUPLICATES
FROM GOLD.DIM_CUSTOMER

UNION ALL

SELECT
    'DIM_PRODUCT',
    COUNT(*),
    COUNT(DISTINCT PRODUCT_ID),
    COUNT(*) - COUNT(DISTINCT PRODUCT_ID)
FROM GOLD.DIM_PRODUCT

UNION ALL

SELECT
    'DIM_SELLER',
    COUNT(*),
    COUNT(DISTINCT SELLER_ID),
    COUNT(*) - COUNT(DISTINCT SELLER_ID)
FROM GOLD.DIM_SELLER

ORDER BY TABLE_NAME;


-- ============================================================
-- 4. AUDIT DU GRAIN FACT_ORDERS
--
-- Grain :
-- 1 ORDER_ID
--
-- Attendu :
-- Duplicates = 0
-- ============================================================

SELECT
    COUNT(*) AS TOTAL_ROWS,

    COUNT(DISTINCT ORDER_ID)
        AS DISTINCT_GRAINS,

    COUNT(*)
    -
    COUNT(DISTINCT ORDER_ID)
        AS DUPLICATES

FROM GOLD.FACT_ORDERS;


-- ============================================================
-- 5. AUDIT DU GRAIN FACT_ORDER_ITEMS
--
-- Grain :
-- (ORDER_ID, ORDER_ITEM_ID)
--
-- Attendu :
-- 0
-- ============================================================

SELECT
    COUNT(*) AS DUPLICATE_GRAINS
FROM (
    SELECT
        ORDER_ID,
        ORDER_ITEM_ID

    FROM GOLD.FACT_ORDER_ITEMS

    GROUP BY
        ORDER_ID,
        ORDER_ITEM_ID

    HAVING COUNT(*) > 1
);


-- ============================================================
-- 6. AUDIT DU GRAIN FACT_PAYMENTS
--
-- Grain :
-- (ORDER_ID, PAYMENT_SEQUENTIAL)
--
-- Attendu :
-- 0
-- ============================================================

SELECT
    COUNT(*) AS DUPLICATE_GRAINS
FROM (
    SELECT
        ORDER_ID,
        PAYMENT_SEQUENTIAL

    FROM GOLD.FACT_PAYMENTS

    GROUP BY
        ORDER_ID,
        PAYMENT_SEQUENTIAL

    HAVING COUNT(*) > 1
);


-- ============================================================
-- 7. AUDIT DU GRAIN FACT_REVIEWS
--
-- Grain :
-- (REVIEW_ID, ORDER_ID)
--
-- Attendu :
-- 0
-- ============================================================

SELECT
    COUNT(*) AS DUPLICATE_GRAINS
FROM (
    SELECT
        REVIEW_ID,
        ORDER_ID

    FROM GOLD.FACT_REVIEWS

    GROUP BY
        REVIEW_ID,
        ORDER_ID

    HAVING COUNT(*) > 1
);


-- ============================================================
-- 8. AUDIT FK FACT_ORDERS
--
-- CUSTOMER_KEY -> DIM_CUSTOMER
-- PURCHASE_DATE_KEY -> DIM_DATE
--
-- Tout doit etre a 0.
-- ============================================================

SELECT
    SUM(
        CASE
            WHEN C.CUSTOMER_KEY IS NULL
            THEN 1
            ELSE 0
        END
    ) AS ERR_CUSTOMER,

    SUM(
        CASE
            WHEN D.DATE_KEY IS NULL
            THEN 1
            ELSE 0
        END
    ) AS ERR_DATE

FROM GOLD.FACT_ORDERS O

LEFT JOIN GOLD.DIM_CUSTOMER C
    ON C.CUSTOMER_KEY = O.CUSTOMER_KEY

LEFT JOIN GOLD.DIM_DATE D
    ON D.DATE_KEY = O.PURCHASE_DATE_KEY;


-- ============================================================
-- 9. AUDIT FK FACT_ORDER_ITEMS
--
-- ORDER_ID          -> FACT_ORDERS
-- CUSTOMER_KEY      -> DIM_CUSTOMER
-- PRODUCT_KEY       -> DIM_PRODUCT
-- SELLER_KEY        -> DIM_SELLER
-- PURCHASE_DATE_KEY -> DIM_DATE
--
-- Tout doit etre a 0.
-- ============================================================

SELECT
    SUM(
        CASE
            WHEN O.ORDER_ID IS NULL
            THEN 1
            ELSE 0
        END
    ) AS ERR_ORDER,

    SUM(
        CASE
            WHEN C.CUSTOMER_KEY IS NULL
            THEN 1
            ELSE 0
        END
    ) AS ERR_CUSTOMER,

    SUM(
        CASE
            WHEN P.PRODUCT_KEY IS NULL
            THEN 1
            ELSE 0
        END
    ) AS ERR_PRODUCT,

    SUM(
        CASE
            WHEN S.SELLER_KEY IS NULL
            THEN 1
            ELSE 0
        END
    ) AS ERR_SELLER,

    SUM(
        CASE
            WHEN D.DATE_KEY IS NULL
            THEN 1
            ELSE 0
        END
    ) AS ERR_DATE

FROM GOLD.FACT_ORDER_ITEMS I

LEFT JOIN GOLD.FACT_ORDERS O
    ON O.ORDER_ID = I.ORDER_ID

LEFT JOIN GOLD.DIM_CUSTOMER C
    ON C.CUSTOMER_KEY = I.CUSTOMER_KEY

LEFT JOIN GOLD.DIM_PRODUCT P
    ON P.PRODUCT_KEY = I.PRODUCT_KEY

LEFT JOIN GOLD.DIM_SELLER S
    ON S.SELLER_KEY = I.SELLER_KEY

LEFT JOIN GOLD.DIM_DATE D
    ON D.DATE_KEY = I.PURCHASE_DATE_KEY;


-- ============================================================
-- 10. AUDIT FK FACT_PAYMENTS
--
-- Tout doit etre a 0.
-- ============================================================

SELECT
    SUM(
        CASE
            WHEN O.ORDER_ID IS NULL
            THEN 1
            ELSE 0
        END
    ) AS ERR_ORDER,

    SUM(
        CASE
            WHEN C.CUSTOMER_KEY IS NULL
            THEN 1
            ELSE 0
        END
    ) AS ERR_CUSTOMER,

    SUM(
        CASE
            WHEN D.DATE_KEY IS NULL
            THEN 1
            ELSE 0
        END
    ) AS ERR_DATE

FROM GOLD.FACT_PAYMENTS P

LEFT JOIN GOLD.FACT_ORDERS O
    ON O.ORDER_ID = P.ORDER_ID

LEFT JOIN GOLD.DIM_CUSTOMER C
    ON C.CUSTOMER_KEY = P.CUSTOMER_KEY

LEFT JOIN GOLD.DIM_DATE D
    ON D.DATE_KEY = P.PURCHASE_DATE_KEY;


-- ============================================================
-- 11. AUDIT FK FACT_REVIEWS
--
-- Tout doit etre a 0.
-- ============================================================

SELECT
    SUM(
        CASE
            WHEN O.ORDER_ID IS NULL
            THEN 1
            ELSE 0
        END
    ) AS ERR_ORDER,

    SUM(
        CASE
            WHEN C.CUSTOMER_KEY IS NULL
            THEN 1
            ELSE 0
        END
    ) AS ERR_CUSTOMER,

    SUM(
        CASE
            WHEN D.DATE_KEY IS NULL
            THEN 1
            ELSE 0
        END
    ) AS ERR_DATE

FROM GOLD.FACT_REVIEWS R

LEFT JOIN GOLD.FACT_ORDERS O
    ON O.ORDER_ID = R.ORDER_ID

LEFT JOIN GOLD.DIM_CUSTOMER C
    ON C.CUSTOMER_KEY = R.CUSTOMER_KEY

LEFT JOIN GOLD.DIM_DATE D
    ON D.DATE_KEY = R.REVIEW_DATE_KEY;


-- ============================================================
-- 12. AUDIT DIM_SELLER -> DIM_GEOGRAPHY
--
-- GEOGRAPHY_KEY = 0 est volontairement autorisee.
-- La ligne UNKNOWN existe dans DIM_GEOGRAPHY.
--
-- Attendu :
-- ERR_GEOGRAPHY = 0
-- ============================================================

SELECT
    SUM(
        CASE
            WHEN G.GEOGRAPHY_KEY IS NULL
            THEN 1
            ELSE 0
        END
    ) AS ERR_GEOGRAPHY

FROM GOLD.DIM_SELLER S

LEFT JOIN GOLD.DIM_GEOGRAPHY G
    ON G.GEOGRAPHY_KEY = S.GEOGRAPHY_KEY;


-- ============================================================
-- 13. VENDEURS SUR GEOGRAPHIE UNKNOWN
--
-- Valeur deja observee :
-- 7
-- ============================================================

SELECT
    COUNT(*) AS SELLERS_GEO_UNKNOWN
FROM GOLD.DIM_SELLER
WHERE GEOGRAPHY_KEY = 0;


-- ============================================================
-- 14. AUDIT DES MESURES FACT_ORDER_ITEMS
--
-- Attendu :
-- 0 pour chaque erreur.
-- ============================================================

SELECT
    SUM(
        CASE
            WHEN PRICE IS NULL
            THEN 1
            ELSE 0
        END
    ) AS PRICE_NULL,

    SUM(
        CASE
            WHEN PRICE <= 0
            THEN 1
            ELSE 0
        END
    ) AS PRICE_INVALID,

    SUM(
        CASE
            WHEN FREIGHT_VALUE IS NULL
            THEN 1
            ELSE 0
        END
    ) AS FREIGHT_NULL,

    SUM(
        CASE
            WHEN FREIGHT_VALUE < 0
            THEN 1
            ELSE 0
        END
    ) AS FREIGHT_INVALID,

    SUM(
        CASE
            WHEN TOTAL_ITEM_VALUE IS NULL
            THEN 1
            ELSE 0
        END
    ) AS TOTAL_NULL,

    SUM(
        CASE
            WHEN ABS(
                TOTAL_ITEM_VALUE
                -
                (PRICE + FREIGHT_VALUE)
            ) > 0.01
            THEN 1
            ELSE 0
        END
    ) AS TOTAL_INCOHERENT

FROM GOLD.FACT_ORDER_ITEMS;


-- ============================================================
-- 15. AUDIT DES MESURES FACT_PAYMENTS
--
-- PAYMENT_VALUE = 0 est autorise.
-- PAYMENT_INSTALLMENTS = 0 est conserve.
--
-- Valeurs negatives interdites.
-- ============================================================

SELECT
    SUM(
        CASE
            WHEN PAYMENT_VALUE IS NULL
            THEN 1
            ELSE 0
        END
    ) AS PAYMENT_NULL,

    SUM(
        CASE
            WHEN PAYMENT_VALUE < 0
            THEN 1
            ELSE 0
        END
    ) AS PAYMENT_NEGATIVE,

    SUM(
        CASE
            WHEN PAYMENT_INSTALLMENTS IS NULL
            THEN 1
            ELSE 0
        END
    ) AS INSTALLMENTS_NULL,

    SUM(
        CASE
            WHEN PAYMENT_INSTALLMENTS < 0
            THEN 1
            ELSE 0
        END
    ) AS INSTALLMENTS_NEGATIVE

FROM GOLD.FACT_PAYMENTS;


-- ============================================================
-- 16. VALEURS PARTICULIERES DES PAIEMENTS
--
-- Controles informatifs.
--
-- Nous avons deja observe :
-- PAYMENT_VALUE = 0       -> 9 lignes
-- INSTALLMENTS = 0        -> 2 lignes
-- ============================================================

SELECT
    SUM(
        CASE
            WHEN PAYMENT_VALUE = 0
            THEN 1
            ELSE 0
        END
    ) AS PAYMENT_ZERO,

    SUM(
        CASE
            WHEN PAYMENT_INSTALLMENTS = 0
            THEN 1
            ELSE 0
        END
    ) AS INSTALLMENTS_ZERO

FROM GOLD.FACT_PAYMENTS;


-- ============================================================
-- 17. AUDIT REVIEW_SCORE
--
-- Attendu :
-- SCORE_NULL    = 0
-- SCORE_INVALID = 0
-- ============================================================

SELECT
    SUM(
        CASE
            WHEN REVIEW_SCORE IS NULL
            THEN 1
            ELSE 0
        END
    ) AS SCORE_NULL,

    SUM(
        CASE
            WHEN REVIEW_SCORE < 1
              OR REVIEW_SCORE > 5
            THEN 1
            ELSE 0
        END
    ) AS SCORE_INVALID

FROM GOLD.FACT_REVIEWS;


-- ============================================================
-- 18. AUDIT DES INDICATEURS DE LIVRAISON
--
-- La regle finale validee est :
--
-- DELIVERY_DELAY_DAYS > 0
--      -> IS_LATE_DELIVERY = 1
--
-- DELIVERY_DELAY_DAYS <= 0
--      -> IS_LATE_DELIVERY = 0
--
-- DELAY NULL
--      -> FLAG NULL
--
-- Attendu :
-- TOTAL_INCOHERENCES = 0