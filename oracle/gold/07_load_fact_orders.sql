-- ============================================================
-- MODERN DATA PLATFORM - OLIST
-- GOLD
-- 07_load_fact_orders.sql
--
-- CHARGEMENT DE GOLD.FACT_ORDERS
--
-- Grain :
-- 1 ligne = 1 ORDER_ID
--
-- Source :
-- SILVER.ORDERS
--
-- Volume attendu :
-- 99 410 commandes
--
-- REGLE METIER DU RETARD :
--
-- DELIVERY_DELAY_DAYS > 0
--     -> commande en retard
--
-- DELIVERY_DELAY_DAYS <= 0
--     -> livraison a l'heure ou en avance
--
-- Livraison non disponible
--     -> retard non calculable
--
-- DELIVERY_DELAY_DAYS et IS_LATE_DELIVERY
-- utilisent exactement la meme granularite :
-- le JOUR.
-- ============================================================


-- ============================================================
-- 0. NETTOYAGE
-- ============================================================

DELETE FROM GOLD.FACT_ORDERS;

COMMIT;


-- ============================================================
-- 1. CHARGEMENT DE FACT_ORDERS
-- ============================================================

INSERT INTO GOLD.FACT_ORDERS (
    ORDER_ID,
    CUSTOMER_KEY,
    PURCHASE_DATE_KEY,
    ORDER_STATUS,
    ORDER_PURCHASE_TIMESTAMP,
    ORDER_APPROVED_AT,
    ORDER_DELIVERED_CARRIER_DATE,
    ORDER_DELIVERED_CUSTOMER_DATE,
    ORDER_ESTIMATED_DELIVERY_DATE,
    DELIVERY_DAYS,
    DELIVERY_DELAY_DAYS,
    IS_LATE_DELIVERY
)
SELECT
    O.ORDER_ID,

    C.CUSTOMER_KEY,

    D.DATE_KEY,

    O.ORDER_STATUS,

    O.ORDER_PURCHASE_TIMESTAMP,

    O.ORDER_APPROVED_AT,

    O.ORDER_DELIVERED_CARRIER_DATE,

    O.ORDER_DELIVERED_CUSTOMER_DATE,

    O.ORDER_ESTIMATED_DELIVERY_DATE,


    -- ========================================================
    -- DELIVERY_DAYS
    --
    -- Nombre de jours entre l'achat et la livraison client.
    -- ========================================================

    CASE
        WHEN O.ORDER_DELIVERED_CUSTOMER_DATE IS NOT NULL
        THEN
            TRUNC(
                CAST(
                    O.ORDER_DELIVERED_CUSTOMER_DATE AS DATE
                )
            )
            -
            TRUNC(
                CAST(
                    O.ORDER_PURCHASE_TIMESTAMP AS DATE
                )
            )
        ELSE NULL
    END AS DELIVERY_DAYS,


    -- ========================================================
    -- DELIVERY_DELAY_DAYS
    --
    -- Livraison reelle - livraison estimee
    --
    -- > 0 : retard
    -- = 0 : livraison le jour estime
    -- < 0 : livraison en avance
    -- ========================================================

    CASE
        WHEN O.ORDER_DELIVERED_CUSTOMER_DATE IS NOT NULL
         AND O.ORDER_ESTIMATED_DELIVERY_DATE IS NOT NULL
        THEN
            TRUNC(
                CAST(
                    O.ORDER_DELIVERED_CUSTOMER_DATE AS DATE
                )
            )
            -
            TRUNC(
                CAST(
                    O.ORDER_ESTIMATED_DELIVERY_DATE AS DATE
                )
            )
        ELSE NULL
    END AS DELIVERY_DELAY_DAYS,


    -- ========================================================
    -- IS_LATE_DELIVERY
    --
    -- Meme granularite que DELIVERY_DELAY_DAYS.
    --
    -- 1    = retard
    -- 0    = a l'heure ou en avance
    -- NULL = non calculable
    -- ========================================================

    CASE
        WHEN O.ORDER_DELIVERED_CUSTOMER_DATE IS NULL
          OR O.ORDER_ESTIMATED_DELIVERY_DATE IS NULL
        THEN NULL

        WHEN
            TRUNC(
                CAST(
                    O.ORDER_DELIVERED_CUSTOMER_DATE AS DATE
                )
            )
            >
            TRUNC(
                CAST(
                    O.ORDER_ESTIMATED_DELIVERY_DATE AS DATE
                )
            )
        THEN 1

        ELSE 0
    END AS IS_LATE_DELIVERY

FROM SILVER.ORDERS O

INNER JOIN GOLD.DIM_CUSTOMER C
    ON C.CUSTOMER_ID = O.CUSTOMER_ID

INNER JOIN GOLD.DIM_DATE D
    ON D.FULL_DATE =
       TRUNC(
           CAST(
               O.ORDER_PURCHASE_TIMESTAMP AS DATE
           )
       );


COMMIT;


-- ============================================================
-- 2. VOLUME TOTAL
--
-- Attendu : 99 410
-- ============================================================

SELECT
    COUNT(*) AS NB_ORDERS
FROM GOLD.FACT_ORDERS;


-- ============================================================
-- 3. ORDER_ID DISTINCTS
--
-- Attendu : 99 410
-- ============================================================

SELECT
    COUNT(DISTINCT ORDER_ID) AS ORDERS_DISTINCTS
FROM GOLD.FACT_ORDERS;


-- ============================================================
-- 4. ORDER_ID DUPLIQUES
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS ORDER_ID_DUPLIQUES
FROM (
    SELECT
        ORDER_ID
    FROM GOLD.FACT_ORDERS
    GROUP BY ORDER_ID
    HAVING COUNT(*) > 1
);


-- ============================================================
-- 5. ORDER_ID NULL
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS ORDER_ID_NULL
FROM GOLD.FACT_ORDERS
WHERE ORDER_ID IS NULL;


-- ============================================================
-- 6. CUSTOMER_KEY NULL
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS CUSTOMER_KEY_NULL
FROM GOLD.FACT_ORDERS
WHERE CUSTOMER_KEY IS NULL;


-- ============================================================
-- 7. PURCHASE_DATE_KEY NULL
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS PURCHASE_DATE_KEY_NULL
FROM GOLD.FACT_ORDERS
WHERE PURCHASE_DATE_KEY IS NULL;


-- ============================================================
-- 8. CONTROLE FK DIM_CUSTOMER
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS ORDERS_SANS_DIM_CUSTOMER
FROM GOLD.FACT_ORDERS O
WHERE NOT EXISTS (
    SELECT 1
    FROM GOLD.DIM_CUSTOMER C
    WHERE C.CUSTOMER_KEY = O.CUSTOMER_KEY
);


-- ============================================================
-- 9. CONTROLE FK DIM_DATE
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS ORDERS_SANS_DIM_DATE
FROM GOLD.FACT_ORDERS O
WHERE NOT EXISTS (
    SELECT 1
    FROM GOLD.DIM_DATE D
    WHERE D.DATE_KEY = O.PURCHASE_DATE_KEY
);


-- ============================================================
-- 10. RECONCILIATION SILVER / GOLD
--
-- Attendu :
-- SILVER_ORDERS = 99 410
-- GOLD_ORDERS   = 99 410
-- ECART         = 0
-- ============================================================

SELECT
    (
        SELECT COUNT(*)
        FROM SILVER.ORDERS
    ) AS SILVER_ORDERS,

    (
        SELECT COUNT(*)
        FROM GOLD.FACT_ORDERS
    ) AS GOLD_ORDERS,

    (
        SELECT COUNT(*)
        FROM SILVER.ORDERS
    )
    -
    (
        SELECT COUNT(*)
        FROM GOLD.FACT_ORDERS
    ) AS ECART

FROM DUAL;


-- ============================================================
-- 11. COMMANDES SILVER ABSENTES DE GOLD
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS SILVER_ORDERS_ABSENTES_GOLD
FROM SILVER.ORDERS S
WHERE NOT EXISTS (
    SELECT 1
    FROM GOLD.FACT_ORDERS G
    WHERE G.ORDER_ID = S.ORDER_ID
);


-- ============================================================
-- 12. COMMANDES GOLD ABSENTES DE SILVER
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS GOLD_ORDERS_ABSENTES_SILVER
FROM GOLD.FACT_ORDERS G
WHERE NOT EXISTS (
    SELECT 1
    FROM SILVER.ORDERS S
    WHERE S.ORDER_ID = G.ORDER_ID
);


-- ============================================================
-- 13. DELIVERY_DAYS NEGATIFS
--
-- Une livraison ne doit pas preceder l'achat.
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS DELIVERY_DAYS_NEGATIFS
FROM GOLD.FACT_ORDERS
WHERE DELIVERY_DAYS < 0;


-- ============================================================
-- 14. FLAG DE RETARD INVALIDE
--
-- Valeurs autorisees :
-- 0, 1 ou NULL
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS LATE_FLAG_INVALIDE
FROM GOLD.FACT_ORDERS
WHERE IS_LATE_DELIVERY IS NOT NULL
  AND IS_LATE_DELIVERY NOT IN (0, 1);


-- ============================================================
-- 15. DELAY > 0 MAIS FLAG DIFFERENT DE 1
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS RETARD_FLAG_INCOHERENT
FROM GOLD.FACT_ORDERS
WHERE DELIVERY_DELAY_DAYS > 0
  AND NVL(IS_LATE_DELIVERY, -1) <> 1;


-- ============================================================
-- 16. DELAY <= 0 MAIS FLAG DIFFERENT DE 0
--
-- Ancienne version :
-- 1 292 incoherences
--
-- Nouvelle version :
-- attendu = 0
-- ============================================================

SELECT
    COUNT(*) AS NON_RETARD_FLAG_INCOHERENT
FROM GOLD.FACT_ORDERS
WHERE DELIVERY_DELAY_DAYS <= 0
  AND NVL(IS_LATE_DELIVERY, -1) <> 0;


-- ============================================================
-- 17. DELAY NULL MAIS FLAG NON NULL
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS DELAY_NULL_FLAG_NON_NULL
FROM GOLD.FACT_ORDERS
WHERE DELIVERY_DELAY_DAYS IS NULL
  AND IS_LATE_DELIVERY IS NOT NULL;


-- ============================================================
-- 18. DELAY NON NULL MAIS FLAG NULL
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS DELAY_NON_NULL_FLAG_NULL
FROM GOLD.FACT_ORDERS
WHERE DELIVERY_DELAY_DAYS IS NOT NULL
  AND IS_LATE_DELIVERY IS NULL;


-- ============================================================
-- 19. REPARTITION DES LIVRAISONS
-- ============================================================

SELECT
    CASE
        WHEN IS_LATE_DELIVERY = 1
            THEN 'LATE'

        WHEN IS_LATE_DELIVERY = 0
            THEN 'ON_TIME_OR_EARLY'

        ELSE 'NOT_AVAILABLE'
    END AS DELIVERY_STATUS,

    COUNT(*) AS NB_ORDERS

FROM GOLD.FACT_ORDERS

GROUP BY
    CASE
        WHEN IS_LATE_DELIVERY = 1
            THEN 'LATE'

        WHEN IS_LATE_DELIVERY = 0
            THEN 'ON_TIME_OR_EARLY'

        ELSE 'NOT_AVAILABLE'
    END

ORDER BY DELIVERY_STATUS;


-- ============================================================
-- 20. STATISTIQUES DELIVERY_DAYS
-- ============================================================

SELECT
    COUNT(DELIVERY_DAYS)
        AS ORDERS_AVEC_DELIVERY_DAYS,

    ROUND(
        AVG(DELIVERY_DAYS),
        2
    ) AS DELIVERY_DAYS_MOYEN,

    MIN(DELIVERY_DAYS)
        AS DELIVERY_DAYS_MIN,

    MAX(DELIVERY_DAYS)
        AS DELIVERY_DAYS_MAX

FROM GOLD.FACT_ORDERS;


-- ============================================================
-- 21. STATISTIQUES DELIVERY_DELAY_DAYS
-- ============================================================

SELECT
    COUNT(DELIVERY_DELAY_DAYS)
        AS ORDERS_AVEC_DELAY,

    ROUND(
        AVG(DELIVERY_DELAY_DAYS),
        2
    ) AS DELAY_MOYEN,

    MIN(DELIVERY_DELAY_DAYS)
        AS DELAY_MIN,

    MAX(DELIVERY_DELAY_DAYS)
        AS DELAY_MAX

FROM GOLD.FACT_ORDERS;


-- ============================================================
-- 22. REPARTITION PAR STATUT DE COMMANDE
-- ============================================================

SELECT
    ORDER_STATUS,
    COUNT(*) AS NB_ORDERS
FROM GOLD.FACT_ORDERS
GROUP BY ORDER_STATUS
ORDER BY NB_ORDERS DESC;


-- ============================================================
-- 23. EXEMPLES DE COMMANDES EN RETARD
-- ============================================================

SELECT *
FROM (
    SELECT
        ORDER_ID,
        CUSTOMER_KEY,
        PURCHASE_DATE_KEY,
        ORDER_STATUS,
        ORDER_PURCHASE_TIMESTAMP,
        ORDER_DELIVERED_CUSTOMER_DATE,
        ORDER_ESTIMATED_DELIVERY_DATE,
        DELIVERY_DAYS,
        DELIVERY_DELAY_DAYS,
        IS_LATE_DELIVERY

    FROM GOLD.FACT_ORDERS

    WHERE IS_LATE_DELIVERY = 1

    ORDER BY DELIVERY_DELAY_DAYS DESC
)
WHERE ROWNUM <= 20;


-- ============================================================
-- 24. COMMANDES LIVREES LE JOUR ESTIME
--
-- Toutes doivent avoir :
--
-- DELIVERY_DELAY_DAYS = 0
-- IS_LATE_DELIVERY    = 0
-- ============================================================

SELECT *
FROM (
    SELECT
        ORDER_ID,
        ORDER_DELIVERED_CUSTOMER_DATE,
        ORDER_ESTIMATED_DELIVERY_DATE,
        DELIVERY_DELAY_DAYS,
        IS_LATE_DELIVERY

    FROM GOLD.FACT_ORDERS

    WHERE DELIVERY_DELAY_DAYS = 0

    ORDER BY ORDER_ID
)
WHERE ROWNUM <= 20;


-- ============================================================
-- 25. CONTROLE GLOBAL DELAY / FLAG
--
-- Controle decisif.
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS TOTAL_INCOHERENCES_DELAY_FLAG
FROM GOLD.FACT_ORDERS
WHERE
       (
           DELIVERY_DELAY_DAYS > 0
           AND NVL(IS_LATE_DELIVERY, -1) <> 1
       )

    OR (
           DELIVERY_DELAY_DAYS <= 0
           AND NVL(IS_LATE_DELIVERY, -1) <> 0
       )

    OR (
           DELIVERY_DELAY_DAYS IS NULL
           AND IS_LATE_DELIVERY IS NOT NULL
       )

    OR (
           DELIVERY_DELAY_DAYS IS NOT NULL
           AND IS_LATE_DELIVERY IS NULL
       );


-- ============================================================
-- 26. SYNTHESE FINALE
-- ============================================================

SELECT
    COUNT(*) AS TOTAL_ORDERS,

    COUNT(DISTINCT ORDER_ID)
        AS ORDER_ID_UNIQUES,

    SUM(
        CASE
            WHEN IS_LATE_DELIVERY = 1
            THEN 1
            ELSE 0
        END
    ) AS ORDERS_EN_RETARD,

    SUM(
        CASE
            WHEN IS_LATE_DELIVERY = 0
            THEN 1
            ELSE 0
        END
    ) AS ORDERS_NON_RETARD,

    SUM(
        CASE
            WHEN IS_LATE_DELIVERY IS NULL
            THEN 1
            ELSE 0
        END
    ) AS RETARD_NON_DISPONIBLE

FROM GOLD.FACT_ORDERS;