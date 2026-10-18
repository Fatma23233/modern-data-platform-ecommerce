-- ============================================================
-- MODERN DATA PLATFORM - OLIST
-- GOLD
-- 08_load_fact_order_items.sql
--
-- CHARGEMENT DE GOLD.FACT_ORDER_ITEMS
--
-- Grain :
-- 1 ligne = (ORDER_ID, ORDER_ITEM_ID)
--
-- Source principale :
-- SILVER.ORDER_ITEMS
--
-- Volume attendu :
-- 112 584 lignes
--
-- Mesures :
-- PRICE
-- FREIGHT_VALUE
-- TOTAL_ITEM_VALUE = PRICE + FREIGHT_VALUE
-- ============================================================


-- ============================================================
-- 0. NETTOYAGE
-- ============================================================

DELETE FROM GOLD.FACT_ORDER_ITEMS;

COMMIT;


-- ============================================================
-- 1. CHARGEMENT DE FACT_ORDER_ITEMS
--
-- Relations utilisees :
--
-- SILVER.ORDER_ITEMS
--        |
--        +--> FACT_ORDERS
--        |       |
--        |       +--> CUSTOMER_KEY
--        |       +--> PURCHASE_DATE_KEY
--        |
--        +--> DIM_PRODUCT
--        |       |
--        |       +--> PRODUCT_KEY
--        |
--        +--> DIM_SELLER
--                |
--                +--> SELLER_KEY
--
-- CUSTOMER_KEY et PURCHASE_DATE_KEY sont recuperes
-- directement depuis FACT_ORDERS.
--
-- Cela garantit que l'article utilise exactement
-- le meme client et la meme date d'achat que sa commande.
-- ============================================================

INSERT INTO GOLD.FACT_ORDER_ITEMS (
    ORDER_ID,
    ORDER_ITEM_ID,
    CUSTOMER_KEY,
    PRODUCT_KEY,
    SELLER_KEY,
    PURCHASE_DATE_KEY,
    PRICE,
    FREIGHT_VALUE,
    TOTAL_ITEM_VALUE
)
SELECT
    I.ORDER_ID,

    I.ORDER_ITEM_ID,

    O.CUSTOMER_KEY,

    P.PRODUCT_KEY,

    S.SELLER_KEY,

    O.PURCHASE_DATE_KEY,

    I.PRICE,

    I.FREIGHT_VALUE,

    I.PRICE + I.FREIGHT_VALUE
        AS TOTAL_ITEM_VALUE

FROM SILVER.ORDER_ITEMS I

INNER JOIN GOLD.FACT_ORDERS O
    ON O.ORDER_ID = I.ORDER_ID

INNER JOIN GOLD.DIM_PRODUCT P
    ON P.PRODUCT_ID = I.PRODUCT_ID

INNER JOIN GOLD.DIM_SELLER S
    ON S.SELLER_ID = I.SELLER_ID;


COMMIT;


-- ============================================================
-- 2. VOLUME TOTAL
--
-- Attendu :
-- 112 584
-- ============================================================

SELECT
    COUNT(*) AS NB_ORDER_ITEMS
FROM GOLD.FACT_ORDER_ITEMS;


-- ============================================================
-- 3. RECONCILIATION SILVER / GOLD
--
-- Attendu :
--
-- SILVER_ITEMS = 112 584
-- GOLD_ITEMS   = 112 584
-- ECART        = 0
-- ============================================================

SELECT
    (
        SELECT COUNT(*)
        FROM SILVER.ORDER_ITEMS
    ) AS SILVER_ITEMS,

    (
        SELECT COUNT(*)
        FROM GOLD.FACT_ORDER_ITEMS
    ) AS GOLD_ITEMS,

    (
        SELECT COUNT(*)
        FROM SILVER.ORDER_ITEMS
    )
    -
    (
        SELECT COUNT(*)
        FROM GOLD.FACT_ORDER_ITEMS
    ) AS ECART

FROM DUAL;


-- ============================================================
-- 4. CONTROLE DU GRAIN
--
-- Grain :
-- (ORDER_ID, ORDER_ITEM_ID)
--
-- Attendu :
-- 0 doublon
-- ============================================================

SELECT
    COUNT(*) AS GRAIN_DUPLIQUE

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
-- 5. ORDER_ID NULL
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS ORDER_ID_NULL
FROM GOLD.FACT_ORDER_ITEMS
WHERE ORDER_ID IS NULL;


-- ============================================================
-- 6. ORDER_ITEM_ID NULL
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS ORDER_ITEM_ID_NULL
FROM GOLD.FACT_ORDER_ITEMS
WHERE ORDER_ITEM_ID IS NULL;


-- ============================================================
-- 7. CUSTOMER_KEY NULL
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS CUSTOMER_KEY_NULL
FROM GOLD.FACT_ORDER_ITEMS
WHERE CUSTOMER_KEY IS NULL;


-- ============================================================
-- 8. PRODUCT_KEY NULL
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS PRODUCT_KEY_NULL
FROM GOLD.FACT_ORDER_ITEMS
WHERE PRODUCT_KEY IS NULL;


-- ============================================================
-- 9. SELLER_KEY NULL
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS SELLER_KEY_NULL
FROM GOLD.FACT_ORDER_ITEMS
WHERE SELLER_KEY IS NULL;


-- ============================================================
-- 10. PURCHASE_DATE_KEY NULL
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS PURCHASE_DATE_KEY_NULL
FROM GOLD.FACT_ORDER_ITEMS
WHERE PURCHASE_DATE_KEY IS NULL;


-- ============================================================
-- 11. CONTROLE FK FACT_ORDERS
--
-- Chaque article doit appartenir a une commande GOLD.
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS ITEMS_SANS_FACT_ORDER
FROM GOLD.FACT_ORDER_ITEMS I

WHERE NOT EXISTS (
    SELECT 1
    FROM GOLD.FACT_ORDERS O
    WHERE O.ORDER_ID = I.ORDER_ID
);


-- ============================================================
-- 12. CONTROLE FK DIM_CUSTOMER
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS ITEMS_SANS_DIM_CUSTOMER
FROM GOLD.FACT_ORDER_ITEMS I

WHERE NOT EXISTS (
    SELECT 1
    FROM GOLD.DIM_CUSTOMER C
    WHERE C.CUSTOMER_KEY = I.CUSTOMER_KEY
);


-- ============================================================
-- 13. CONTROLE FK DIM_PRODUCT
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS ITEMS_SANS_DIM_PRODUCT
FROM GOLD.FACT_ORDER_ITEMS I

WHERE NOT EXISTS (
    SELECT 1
    FROM GOLD.DIM_PRODUCT P
    WHERE P.PRODUCT_KEY = I.PRODUCT_KEY
);


-- ============================================================
-- 14. CONTROLE FK DIM_SELLER
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS ITEMS_SANS_DIM_SELLER
FROM GOLD.FACT_ORDER_ITEMS I

WHERE NOT EXISTS (
    SELECT 1
    FROM GOLD.DIM_SELLER S
    WHERE S.SELLER_KEY = I.SELLER_KEY
);


-- ============================================================
-- 15. CONTROLE FK DIM_DATE
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS ITEMS_SANS_DIM_DATE
FROM GOLD.FACT_ORDER_ITEMS I

WHERE NOT EXISTS (
    SELECT 1
    FROM GOLD.DIM_DATE D
    WHERE D.DATE_KEY = I.PURCHASE_DATE_KEY
);


-- ============================================================
-- 16. ARTICLES SILVER ABSENTS DE GOLD
--
-- Controle ligne par ligne.
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS SILVER_ITEMS_ABSENTS_GOLD
FROM SILVER.ORDER_ITEMS S

WHERE NOT EXISTS (
    SELECT 1
    FROM GOLD.FACT_ORDER_ITEMS G
    WHERE G.ORDER_ID = S.ORDER_ID
      AND G.ORDER_ITEM_ID = S.ORDER_ITEM_ID
);


-- ============================================================
-- 17. ARTICLES GOLD ABSENTS DE SILVER
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS GOLD_ITEMS_ABSENTS_SILVER
FROM GOLD.FACT_ORDER_ITEMS G

WHERE NOT EXISTS (
    SELECT 1
    FROM SILVER.ORDER_ITEMS S
    WHERE S.ORDER_ID = G.ORDER_ID
      AND S.ORDER_ITEM_ID = G.ORDER_ITEM_ID
);


-- ============================================================
-- 18. PRIX NULL
--
-- Normalement impossible avec la structure actuelle.
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS PRICE_NULL
FROM GOLD.FACT_ORDER_ITEMS
WHERE PRICE IS NULL;


-- ============================================================
-- 19. PRIX INVALIDE
--
-- La contrainte GOLD impose PRICE > 0.
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS PRICE_INVALIDE
FROM GOLD.FACT_ORDER_ITEMS
WHERE PRICE <= 0;


-- ============================================================
-- 20. FREIGHT_VALUE NULL
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS FREIGHT_VALUE_NULL
FROM GOLD.FACT_ORDER_ITEMS
WHERE FREIGHT_VALUE IS NULL;


-- ============================================================
-- 21. FREIGHT_VALUE INVALIDE
--
-- Une valeur egale a 0 est autorisee.
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS FREIGHT_VALUE_INVALIDE
FROM GOLD.FACT_ORDER_ITEMS
WHERE FREIGHT_VALUE < 0;


-- ============================================================
-- 22. TOTAL_ITEM_VALUE NULL
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS TOTAL_ITEM_VALUE_NULL
FROM GOLD.FACT_ORDER_ITEMS
WHERE TOTAL_ITEM_VALUE IS NULL;


-- ============================================================
-- 23. CONTROLE DU CALCUL TOTAL_ITEM_VALUE
--
-- Regle :
--
-- TOTAL_ITEM_VALUE = PRICE + FREIGHT_VALUE
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS TOTAL_ITEM_VALUE_INCOHERENT
FROM GOLD.FACT_ORDER_ITEMS

WHERE ABS(
    TOTAL_ITEM_VALUE
    -
    (PRICE + FREIGHT_VALUE)
) > 0.01;


-- ============================================================
-- 24. COHERENCE CUSTOMER_KEY AVEC FACT_ORDERS
--
-- L'article doit avoir le meme CUSTOMER_KEY
-- que sa commande.
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS CUSTOMER_KEY_INCOHERENT
FROM GOLD.FACT_ORDER_ITEMS I

INNER JOIN GOLD.FACT_ORDERS O
    ON O.ORDER_ID = I.ORDER_ID

WHERE I.CUSTOMER_KEY <> O.CUSTOMER_KEY;


-- ============================================================
-- 25. COHERENCE PURCHASE_DATE_KEY AVEC FACT_ORDERS
--
-- L'article doit avoir la meme date d'achat
-- que sa commande.
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS PURCHASE_DATE_KEY_INCOHERENT
FROM GOLD.FACT_ORDER_ITEMS I

INNER JOIN GOLD.FACT_ORDERS O
    ON O.ORDER_ID = I.ORDER_ID

WHERE I.PURCHASE_DATE_KEY <> O.PURCHASE_DATE_KEY;


-- ============================================================
-- 26. COHERENCE PRODUCT_KEY AVEC SILVER
--
-- On verifie que PRODUCT_KEY pointe bien
-- vers le PRODUCT_ID de la ligne SILVER.
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS PRODUCT_KEY_INCOHERENT

FROM GOLD.FACT_ORDER_ITEMS G

INNER JOIN SILVER.ORDER_ITEMS I
    ON I.ORDER_ID = G.ORDER_ID
   AND I.ORDER_ITEM_ID = G.ORDER_ITEM_ID

INNER JOIN GOLD.DIM_PRODUCT P
    ON P.PRODUCT_KEY = G.PRODUCT_KEY

WHERE P.PRODUCT_ID <> I.PRODUCT_ID;


-- ============================================================
-- 27. COHERENCE SELLER_KEY AVEC SILVER
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS SELLER_KEY_INCOHERENT

FROM GOLD.FACT_ORDER_ITEMS G

INNER JOIN SILVER.ORDER_ITEMS I
    ON I.ORDER_ID = G.ORDER_ID
   AND I.ORDER_ITEM_ID = G.ORDER_ITEM_ID

INNER JOIN GOLD.DIM_SELLER S
    ON S.SELLER_KEY = G.SELLER_KEY

WHERE S.SELLER_ID <> I.SELLER_ID;


-- ============================================================
-- 28. STATISTIQUES COMMERCIALES
-- ============================================================

SELECT
    COUNT(*) AS NB_ITEMS,

    ROUND(
        SUM(PRICE),
        2
    ) AS TOTAL_PRICE,

    ROUND(
        SUM(FREIGHT_VALUE),
        2
    ) AS TOTAL_FREIGHT,

    ROUND(
        SUM(TOTAL_ITEM_VALUE),
        2
    ) AS TOTAL_ITEM_VALUE,

    ROUND(
        AVG(PRICE),
        2
    ) AS PRICE_MOYEN,

    ROUND(
        AVG(FREIGHT_VALUE),
        2
    ) AS FREIGHT_MOYEN

FROM GOLD.FACT_ORDER_ITEMS;


-- ============================================================
-- 29. NOMBRE DE COMMANDES AYANT DES ARTICLES
-- ============================================================

SELECT
    COUNT(DISTINCT ORDER_ID)
        AS ORDERS_AVEC_ITEMS
FROM GOLD.FACT_ORDER_ITEMS;


-- ============================================================
-- 30. ARTICLES PAR COMMANDE
-- ============================================================

SELECT
    MIN(NB_ITEMS)
        AS MIN_ITEMS_PAR_ORDER,

    ROUND(
        AVG(NB_ITEMS),
        2
    ) AS AVG_ITEMS_PAR_ORDER,

    MAX(NB_ITEMS)
        AS MAX_ITEMS_PAR_ORDER

FROM (
    SELECT
        ORDER_ID,
        COUNT(*) AS NB_ITEMS

    FROM GOLD.FACT_ORDER_ITEMS

    GROUP BY ORDER_ID
);


-- ============================================================
-- 31. APERCU DES DONNEES
-- ============================================================

SELECT *
FROM (
    SELECT
        ORDER_ID,
        ORDER_ITEM_ID,
        CUSTOMER_KEY,
        PRODUCT_KEY,
        SELLER_KEY,
        PURCHASE_DATE_KEY,
        PRICE,
        FREIGHT_VALUE,
        TOTAL_ITEM_VALUE

    FROM GOLD.FACT_ORDER_ITEMS

    ORDER BY
        ORDER_ID,
        ORDER_ITEM_ID
)
WHERE ROWNUM <= 20;


-- ============================================================
-- 32. SYNTHESE DES CONTROLES DE MESURES
--
-- Les trois compteurs d'erreur doivent etre 0.
-- ============================================================

SELECT
    COUNT(*) AS TOTAL_ITEMS,

    COUNT(
        DISTINCT ORDER_ID || ':' || TO_CHAR(ORDER_ITEM_ID)
    ) AS GRAINS_DISTINCTS,

    SUM(
        CASE
            WHEN PRICE <= 0
            THEN 1
            ELSE 0
        END
    ) AS PRICE_INVALIDES,

    SUM(
        CASE
            WHEN FREIGHT_VALUE < 0
            THEN 1
            ELSE 0
        END
    ) AS FREIGHT_INVALIDES,

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
    ) AS TOTAL_INCOHERENTS

FROM GOLD.FACT_ORDER_ITEMS;