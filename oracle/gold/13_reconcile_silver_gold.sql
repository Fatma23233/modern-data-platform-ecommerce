-- ============================================================
-- MODERN DATA PLATFORM - OLIST
-- GOLD
-- 13_reconcile_silver_gold.sql
--
-- RECONCILIATION SILVER -> GOLD
--
-- Objectifs :
-- 1. Comparer les volumes SILVER / GOLD
-- 2. Rechercher les lignes absentes
-- 3. Rechercher les lignes supplementaires
-- 4. Verifier la conservation des mesures
-- 5. Verifier les mappings vers les dimensions
-- 6. Produire une synthese finale
--
-- Ce script ne modifie aucune donnee.
-- ============================================================


-- ============================================================
-- PARTIE A
-- RECONCILIATION DES VOLUMES
-- ============================================================


-- ============================================================
-- 1. VOLUMES SILVER / GOLD
--
-- ECART attendu :
-- 0 pour toutes les entites.
-- ============================================================

SELECT
    'CUSTOMERS' AS ENTITY,

    (SELECT COUNT(*) FROM SILVER.CUSTOMERS)
        AS SILVER_COUNT,

    (SELECT COUNT(*) FROM GOLD.DIM_CUSTOMER)
        AS GOLD_COUNT,

    (SELECT COUNT(*) FROM SILVER.CUSTOMERS)
    -
    (SELECT COUNT(*) FROM GOLD.DIM_CUSTOMER)
        AS ECART

FROM DUAL

UNION ALL

SELECT
    'PRODUCTS',

    (SELECT COUNT(*) FROM SILVER.PRODUCTS),

    (SELECT COUNT(*) FROM GOLD.DIM_PRODUCT),

    (SELECT COUNT(*) FROM SILVER.PRODUCTS)
    -
    (SELECT COUNT(*) FROM GOLD.DIM_PRODUCT)

FROM DUAL

UNION ALL

SELECT
    'SELLERS',

    (SELECT COUNT(*) FROM SILVER.SELLERS),

    (SELECT COUNT(*) FROM GOLD.DIM_SELLER),

    (SELECT COUNT(*) FROM SILVER.SELLERS)
    -
    (SELECT COUNT(*) FROM GOLD.DIM_SELLER)

FROM DUAL

UNION ALL

SELECT
    'ORDERS',

    (SELECT COUNT(*) FROM SILVER.ORDERS),

    (SELECT COUNT(*) FROM GOLD.FACT_ORDERS),

    (SELECT COUNT(*) FROM SILVER.ORDERS)
    -
    (SELECT COUNT(*) FROM GOLD.FACT_ORDERS)

FROM DUAL

UNION ALL

SELECT
    'ORDER_ITEMS',

    (SELECT COUNT(*) FROM SILVER.ORDER_ITEMS),

    (SELECT COUNT(*) FROM GOLD.FACT_ORDER_ITEMS),

    (SELECT COUNT(*) FROM SILVER.ORDER_ITEMS)
    -
    (SELECT COUNT(*) FROM GOLD.FACT_ORDER_ITEMS)

FROM DUAL

UNION ALL

SELECT
    'PAYMENTS',

    (SELECT COUNT(*) FROM SILVER.PAYMENTS),

    (SELECT COUNT(*) FROM GOLD.FACT_PAYMENTS),

    (SELECT COUNT(*) FROM SILVER.PAYMENTS)
    -
    (SELECT COUNT(*) FROM GOLD.FACT_PAYMENTS)

FROM DUAL

UNION ALL

SELECT
    'REVIEWS',

    (SELECT COUNT(*) FROM SILVER.REVIEWS),

    (SELECT COUNT(*) FROM GOLD.FACT_REVIEWS),

    (SELECT COUNT(*) FROM SILVER.REVIEWS)
    -
    (SELECT COUNT(*) FROM GOLD.FACT_REVIEWS)

FROM DUAL

ORDER BY ENTITY;


-- ============================================================
-- PARTIE B
-- RECONCILIATION DES DIMENSIONS
-- ============================================================


-- ============================================================
-- 2. CUSTOMERS SILVER ABSENTS DE GOLD
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS CUSTOMERS_SILVER_ABSENTS_GOLD
FROM SILVER.CUSTOMERS S
WHERE NOT EXISTS (
    SELECT 1
    FROM GOLD.DIM_CUSTOMER G
    WHERE G.CUSTOMER_ID = S.CUSTOMER_ID
);


-- ============================================================
-- 3. CUSTOMERS GOLD ABSENTS DE SILVER
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS CUSTOMERS_GOLD_ABSENTS_SILVER
FROM GOLD.DIM_CUSTOMER G
WHERE NOT EXISTS (
    SELECT 1
    FROM SILVER.CUSTOMERS S
    WHERE S.CUSTOMER_ID = G.CUSTOMER_ID
);


-- ============================================================
-- 4. PRODUCTS SILVER ABSENTS DE GOLD
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS PRODUCTS_SILVER_ABSENTS_GOLD
FROM SILVER.PRODUCTS S
WHERE NOT EXISTS (
    SELECT 1
    FROM GOLD.DIM_PRODUCT G
    WHERE G.PRODUCT_ID = S.PRODUCT_ID
);


-- ============================================================
-- 5. PRODUCTS GOLD ABSENTS DE SILVER
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS PRODUCTS_GOLD_ABSENTS_SILVER
FROM GOLD.DIM_PRODUCT G
WHERE NOT EXISTS (
    SELECT 1
    FROM SILVER.PRODUCTS S
    WHERE S.PRODUCT_ID = G.PRODUCT_ID
);


-- ============================================================
-- 6. SELLERS SILVER ABSENTS DE GOLD
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS SELLERS_SILVER_ABSENTS_GOLD
FROM SILVER.SELLERS S
WHERE NOT EXISTS (
    SELECT 1
    FROM GOLD.DIM_SELLER G
    WHERE G.SELLER_ID = S.SELLER_ID
);


-- ============================================================
-- 7. SELLERS GOLD ABSENTS DE SILVER
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS SELLERS_GOLD_ABSENTS_SILVER
FROM GOLD.DIM_SELLER G
WHERE NOT EXISTS (
    SELECT 1
    FROM SILVER.SELLERS S
    WHERE S.SELLER_ID = G.SELLER_ID
);


-- ============================================================
-- PARTIE C
-- RECONCILIATION FACT_ORDERS
-- ============================================================


-- ============================================================
-- 8. ORDERS SILVER ABSENTES DE GOLD
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS ORDERS_SILVER_ABSENTES_GOLD
FROM SILVER.ORDERS S
WHERE NOT EXISTS (
    SELECT 1
    FROM GOLD.FACT_ORDERS G
    WHERE G.ORDER_ID = S.ORDER_ID
);


-- ============================================================
-- 9. ORDERS GOLD ABSENTES DE SILVER
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS ORDERS_GOLD_ABSENTES_SILVER
FROM GOLD.FACT_ORDERS G
WHERE NOT EXISTS (
    SELECT 1
    FROM SILVER.ORDERS S
    WHERE S.ORDER_ID = G.ORDER_ID
);


-- ============================================================
-- 10. COHERENCE ORDER_STATUS
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS ORDER_STATUS_INCOHERENT
FROM SILVER.ORDERS S

INNER JOIN GOLD.FACT_ORDERS G
    ON G.ORDER_ID = S.ORDER_ID

WHERE
       G.ORDER_STATUS <> S.ORDER_STATUS

    OR (
        G.ORDER_STATUS IS NULL
        AND S.ORDER_STATUS IS NOT NULL
    )

    OR (
        G.ORDER_STATUS IS NOT NULL
        AND S.ORDER_STATUS IS NULL
    );


-- ============================================================
-- 11. COHERENCE CUSTOMER
--
-- Le CUSTOMER_KEY de GOLD doit pointer sur
-- le CUSTOMER_ID de SILVER.
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS ORDER_CUSTOMER_INCOHERENT
FROM SILVER.ORDERS S

INNER JOIN GOLD.FACT_ORDERS G
    ON G.ORDER_ID = S.ORDER_ID

INNER JOIN GOLD.DIM_CUSTOMER C
    ON C.CUSTOMER_KEY = G.CUSTOMER_KEY

WHERE C.CUSTOMER_ID <> S.CUSTOMER_ID;


-- ============================================================
-- 12. COHERENCE PURCHASE_DATE_KEY
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS ORDER_DATE_INCOHERENTE
FROM SILVER.ORDERS S

INNER JOIN GOLD.FACT_ORDERS G
    ON G.ORDER_ID = S.ORDER_ID

INNER JOIN GOLD.DIM_DATE D
    ON D.DATE_KEY = G.PURCHASE_DATE_KEY

WHERE D.FULL_DATE <>
      TRUNC(
          CAST(
              S.ORDER_PURCHASE_TIMESTAMP AS DATE
          )
      );


-- ============================================================
-- PARTIE D
-- RECONCILIATION FACT_ORDER_ITEMS
-- ============================================================


-- ============================================================
-- 13. ORDER_ITEMS SILVER ABSENTS DE GOLD
--
-- Grain :
-- (ORDER_ID, ORDER_ITEM_ID)
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS ITEMS_SILVER_ABSENTS_GOLD
FROM SILVER.ORDER_ITEMS S

WHERE NOT EXISTS (
    SELECT 1
    FROM GOLD.FACT_ORDER_ITEMS G
    WHERE G.ORDER_ID = S.ORDER_ID
      AND G.ORDER_ITEM_ID = S.ORDER_ITEM_ID
);


-- ============================================================
-- 14. ORDER_ITEMS GOLD ABSENTS DE SILVER
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS ITEMS_GOLD_ABSENTS_SILVER
FROM GOLD.FACT_ORDER_ITEMS G

WHERE NOT EXISTS (
    SELECT 1
    FROM SILVER.ORDER_ITEMS S
    WHERE S.ORDER_ID = G.ORDER_ID
      AND S.ORDER_ITEM_ID = G.ORDER_ITEM_ID
);


-- ============================================================
-- 15. COHERENCE PRODUCT_KEY
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS PRODUCT_MAPPING_INCOHERENT
FROM SILVER.ORDER_ITEMS S

INNER JOIN GOLD.FACT_ORDER_ITEMS G
    ON G.ORDER_ID = S.ORDER_ID
   AND G.ORDER_ITEM_ID = S.ORDER_ITEM_ID

INNER JOIN GOLD.DIM_PRODUCT P
    ON P.PRODUCT_KEY = G.PRODUCT_KEY

WHERE P.PRODUCT_ID <> S.PRODUCT_ID;


-- ============================================================
-- 16. COHERENCE SELLER_KEY
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS SELLER_MAPPING_INCOHERENT
FROM SILVER.ORDER_ITEMS S

INNER JOIN GOLD.FACT_ORDER_ITEMS G
    ON G.ORDER_ID = S.ORDER_ID
   AND G.ORDER_ITEM_ID = S.ORDER_ITEM_ID

INNER JOIN GOLD.DIM_SELLER D
    ON D.SELLER_KEY = G.SELLER_KEY

WHERE D.SELLER_ID <> S.SELLER_ID;


-- ============================================================
-- 17. COHERENCE PRICE
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS PRICE_INCOHERENT
FROM SILVER.ORDER_ITEMS S

INNER JOIN GOLD.FACT_ORDER_ITEMS G
    ON G.ORDER_ID = S.ORDER_ID
   AND G.ORDER_ITEM_ID = S.ORDER_ITEM_ID

WHERE ABS(
    G.PRICE - S.PRICE
) > 0.01;


-- ============================================================
-- 18. COHERENCE FREIGHT_VALUE
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS FREIGHT_INCOHERENT
FROM SILVER.ORDER_ITEMS S

INNER JOIN GOLD.FACT_ORDER_ITEMS G
    ON G.ORDER_ID = S.ORDER_ID
   AND G.ORDER_ITEM_ID = S.ORDER_ITEM_ID

WHERE ABS(
    G.FREIGHT_VALUE - S.FREIGHT_VALUE
) > 0.01;


-- ============================================================
-- 19. VALIDATION TOTAL_ITEM_VALUE
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS ITEM_TOTAL_INCOHERENT
FROM GOLD.FACT_ORDER_ITEMS
WHERE ABS(
    TOTAL_ITEM_VALUE
    -
    (PRICE + FREIGHT_VALUE)
) > 0.01;


-- ============================================================
-- PARTIE E
-- RECONCILIATION FACT_PAYMENTS
-- ============================================================


-- ============================================================
-- 20. PAYMENTS SILVER ABSENTS DE GOLD
--
-- Grain :
-- (ORDER_ID, PAYMENT_SEQUENTIAL)
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS PAYMENTS_SILVER_ABSENTS_GOLD
FROM SILVER.PAYMENTS S

WHERE NOT EXISTS (
    SELECT 1
    FROM GOLD.FACT_PAYMENTS G
    WHERE G.ORDER_ID = S.ORDER_ID
      AND G.PAYMENT_SEQUENTIAL = S.PAYMENT_SEQUENTIAL
);


-- ============================================================
-- 21. PAYMENTS GOLD ABSENTS DE SILVER
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS PAYMENTS_GOLD_ABSENTS_SILVER
FROM GOLD.FACT_PAYMENTS G

WHERE NOT EXISTS (
    SELECT 1
    FROM SILVER.PAYMENTS S
    WHERE S.ORDER_ID = G.ORDER_ID
      AND S.PAYMENT_SEQUENTIAL = G.PAYMENT_SEQUENTIAL
);


-- ============================================================
-- 22. COHERENCE PAYMENT_TYPE
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS PAYMENT_TYPE_INCOHERENT
FROM SILVER.PAYMENTS S

INNER JOIN GOLD.FACT_PAYMENTS G
    ON G.ORDER_ID = S.ORDER_ID
   AND G.PAYMENT_SEQUENTIAL = S.PAYMENT_SEQUENTIAL

WHERE
       G.PAYMENT_TYPE <> S.PAYMENT_TYPE

    OR (
        G.PAYMENT_TYPE IS NULL
        AND S.PAYMENT_TYPE IS NOT NULL
    )

    OR (
        G.PAYMENT_TYPE IS NOT NULL
        AND S.PAYMENT_TYPE IS NULL
    );


-- ============================================================
-- 23. COHERENCE PAYMENT_INSTALLMENTS
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS INSTALLMENTS_INCOHERENTS
FROM SILVER.PAYMENTS S

INNER JOIN GOLD.FACT_PAYMENTS G
    ON G.ORDER_ID = S.ORDER_ID
   AND G.PAYMENT_SEQUENTIAL = S.PAYMENT_SEQUENTIAL

WHERE
       G.PAYMENT_INSTALLMENTS <> S.PAYMENT_INSTALLMENTS

    OR (
        G.PAYMENT_INSTALLMENTS IS NULL
        AND S.PAYMENT_INSTALLMENTS IS NOT NULL
    )

    OR (
        G.PAYMENT_INSTALLMENTS IS NOT NULL
        AND S.PAYMENT_INSTALLMENTS IS NULL
    );


-- ============================================================
-- 24. COHERENCE PAYMENT_VALUE
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS PAYMENT_VALUE_INCOHERENT
FROM SILVER.PAYMENTS S

INNER JOIN GOLD.FACT_PAYMENTS G
    ON G.ORDER_ID = S.ORDER_ID
   AND G.PAYMENT_SEQUENTIAL = S.PAYMENT_SEQUENTIAL

WHERE ABS(
    G.PAYMENT_VALUE - S.PAYMENT_VALUE
) > 0.01;


-- ============================================================
-- PARTIE F
-- RECONCILIATION FACT_REVIEWS
-- ============================================================


-- ============================================================
-- 25. REVIEWS SILVER ABSENTS DE GOLD
--
-- Grain :
-- (REVIEW_ID, ORDER_ID)
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS REVIEWS_SILVER_ABSENTS_GOLD
FROM SILVER.REVIEWS S

WHERE NOT EXISTS (
    SELECT 1
    FROM GOLD.FACT_REVIEWS G
    WHERE G.REVIEW_ID = S.REVIEW_ID
      AND G.ORDER_ID = S.ORDER_ID
);


-- ============================================================
-- 26. REVIEWS GOLD ABSENTS DE SILVER
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS REVIEWS_GOLD_ABSENTS_SILVER
FROM GOLD.FACT_REVIEWS G

WHERE NOT EXISTS (
    SELECT 1
    FROM SILVER.REVIEWS S
    WHERE S.REVIEW_ID = G.REVIEW_ID
      AND S.ORDER_ID = G.ORDER_ID
);


-- ============================================================
-- 27. COHERENCE REVIEW_SCORE
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS REVIEW_SCORE_INCOHERENT
FROM SILVER.REVIEWS S

INNER JOIN GOLD.FACT_REVIEWS G
    ON G.REVIEW_ID = S.REVIEW_ID
   AND G.ORDER_ID = S.ORDER_ID

WHERE
       G.REVIEW_SCORE <> S.REVIEW_SCORE

    OR (
        G.REVIEW_SCORE IS NULL
        AND S.REVIEW_SCORE IS NOT NULL
    )

    OR (
        G.REVIEW_SCORE IS NOT NULL
        AND S.REVIEW_SCORE IS NULL
    );


-- ============================================================
-- 28. COHERENCE REVIEW_DATE_KEY
--
-- REVIEW_DATE_KEY doit correspondre a
-- REVIEW_CREATION_DATE de SILVER.
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS REVIEW_DATE_INCOHERENTE
FROM SILVER.REVIEWS S

INNER JOIN GOLD.FACT_REVIEWS G
    ON G.REVIEW_ID = S.REVIEW_ID
   AND G.ORDER_ID = S.ORDER_ID

INNER JOIN GOLD.DIM_DATE D
    ON D.DATE_KEY = G.REVIEW_DATE_KEY

WHERE D.FULL_DATE <>
      TRUNC(
          CAST(
              S.REVIEW_CREATION_DATE AS DATE
          )
      );


-- ============================================================
-- PARTIE G
-- RECONCILIATION DES MONTANTS
-- ============================================================


-- ============================================================
-- 29. SOMMES SILVER / GOLD ORDER_ITEMS
--
-- Les montants doivent etre identiques.
-- ============================================================

SELECT
    ROUND(
        (SELECT SUM(PRICE)
         FROM SILVER.ORDER_ITEMS),
        2
    ) AS SILVER_PRICE,

    ROUND(
        (SELECT SUM(PRICE)
         FROM GOLD.FACT_ORDER_ITEMS),
        2
    ) AS GOLD_PRICE,

    ROUND(
        (SELECT SUM(PRICE)
         FROM SILVER.ORDER_ITEMS)
        -
        (SELECT SUM(PRICE)
         FROM GOLD.FACT_ORDER_ITEMS),
        2
    ) AS PRICE_ECART,

    ROUND(
        (SELECT SUM(FREIGHT_VALUE)
         FROM SILVER.ORDER_ITEMS),
        2
    ) AS SILVER_FREIGHT,

    ROUND(
        (SELECT SUM(FREIGHT_VALUE)
         FROM GOLD.FACT_ORDER_ITEMS),
        2
    ) AS GOLD_FREIGHT,

    ROUND(
        (SELECT SUM(FREIGHT_VALUE)
         FROM SILVER.ORDER_ITEMS)
        -
        (SELECT SUM(FREIGHT_VALUE)
         FROM GOLD.FACT_ORDER_ITEMS),
        2
    ) AS FREIGHT_ECART

FROM DUAL;


-- ============================================================
-- 30. SOMMES SILVER / GOLD PAYMENTS
--
-- Attendu :
-- PAYMENT_ECART = 0
-- ============================================================

SELECT
    ROUND(
        (SELECT SUM(PAYMENT_VALUE)
         FROM SILVER.PAYMENTS),
        2
    ) AS SILVER_PAYMENT,

    ROUND(
        (SELECT SUM(PAYMENT_VALUE)
         FROM GOLD.FACT_PAYMENTS),
        2
    ) AS GOLD_PAYMENT,

    ROUND(
        (SELECT SUM(PAYMENT_VALUE)
         FROM SILVER.PAYMENTS)
        -
        (SELECT SUM(PAYMENT_VALUE)
         FROM GOLD.FACT_PAYMENTS),
        2
    ) AS PAYMENT_ECART

FROM DUAL;


-- ============================================================
-- PARTIE H
-- CONTROLE DES GRAINS
-- ============================================================


-- ============================================================
-- 31. FACT_ORDERS
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS DUPLICATE_ORDERS
FROM (
    SELECT
        ORDER_ID
    FROM GOLD.FACT_ORDERS
    GROUP BY ORDER_ID
    HAVING COUNT(*) > 1
);


-- ============================================================
-- 32. FACT_ORDER_ITEMS
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS DUPLICATE_ORDER_ITEMS
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
-- 33. FACT_PAYMENTS
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS DUPLICATE_PAYMENTS
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
-- 34. FACT_REVIEWS
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS DUPLICATE_REVIEWS
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
-- PARTIE I
-- SYNTHESE DE RECONCILIATION
-- ============================================================


-- ============================================================
-- 35. SYNTHESE FINALE
--
-- Toutes les valeurs ERROR_COUNT doivent etre 0.
-- ============================================================

SELECT
    'CUSTOMERS_MISSING_GOLD' AS CONTROL_NAME,
    COUNT(*) AS ERROR_COUNT
FROM SILVER.CUSTOMERS S
WHERE NOT EXISTS (
    SELECT 1
    FROM GOLD.DIM_CUSTOMER G
    WHERE G.CUSTOMER_ID = S.CUSTOMER_ID
)


UNION ALL


SELECT
    'PRODUCTS_MISSING_GOLD',
    COUNT(*)
FROM SILVER.PRODUCTS S
WHERE NOT EXISTS (
    SELECT 1
    FROM GOLD.DIM_PRODUCT G
    WHERE G.PRODUCT_ID = S.PRODUCT_ID
)


UNION ALL


SELECT
    'SELLERS_MISSING_GOLD',
    COUNT(*)
FROM SILVER.SELLERS S
WHERE NOT EXISTS (
    SELECT 1
    FROM GOLD.DIM_SELLER G
    WHERE G.SELLER_ID = S.SELLER_ID
)


UNION ALL


SELECT
    'ORDERS_MISSING_GOLD',
    COUNT(*)
FROM SILVER.ORDERS S
WHERE NOT EXISTS (
    SELECT 1
    FROM GOLD.FACT_ORDERS G
    WHERE G.ORDER_ID = S.ORDER_ID
)


UNION ALL


SELECT
    'ORDER_ITEMS_MISSING_GOLD',
    COUNT(*)
FROM SILVER.ORDER_ITEMS S
WHERE NOT EXISTS (
    SELECT 1
    FROM GOLD.FACT_ORDER_ITEMS G
    WHERE G.ORDER_ID = S.ORDER_ID
      AND G.ORDER_ITEM_ID = S.ORDER_ITEM_ID
)


UNION ALL


SELECT
    'PAYMENTS_MISSING_GOLD',
    COUNT(*)
FROM SILVER.PAYMENTS S
WHERE NOT EXISTS (
    SELECT 1
    FROM GOLD.FACT_PAYMENTS G
    WHERE G.ORDER_ID = S.ORDER_ID
      AND G.PAYMENT_SEQUENTIAL = S.PAYMENT_SEQUENTIAL
)


UNION ALL


SELECT
    'REVIEWS_MISSING_GOLD',
    COUNT(*)
FROM SILVER.REVIEWS S
WHERE NOT EXISTS (
    SELECT 1
    FROM GOLD.FACT_REVIEWS G
    WHERE G.REVIEW_ID = S.REVIEW_ID
      AND G.ORDER_ID = S.ORDER_ID
)


UNION ALL


SELECT
    'ORDER_STATUS',
    COUNT(*)
FROM SILVER.ORDERS S
INNER JOIN GOLD.FACT_ORDERS G
    ON G.ORDER_ID = S.ORDER_ID
WHERE
       G.ORDER_STATUS <> S.ORDER_STATUS
    OR (
           G.ORDER_STATUS IS NULL
           AND S.ORDER_STATUS IS NOT NULL
       )
    OR (
           G.ORDER_STATUS IS NOT NULL
           AND S.ORDER_STATUS IS NULL
       )


UNION ALL


SELECT
    'ORDER_ITEM_PRICE',
    COUNT(*)
FROM SILVER.ORDER_ITEMS S
INNER JOIN GOLD.FACT_ORDER_ITEMS G
    ON G.ORDER_ID = S.ORDER_ID
   AND G.ORDER_ITEM_ID = S.ORDER_ITEM_ID
WHERE ABS(G.PRICE - S.PRICE) > 0.01


UNION ALL


SELECT
    'ORDER_ITEM_FREIGHT',
    COUNT(*)
FROM SILVER.ORDER_ITEMS S
INNER JOIN GOLD.FACT_ORDER_ITEMS G
    ON G.ORDER_ID = S.ORDER_ID
   AND G.ORDER_ITEM_ID = S.ORDER_ITEM_ID
WHERE ABS(
    G.FREIGHT_VALUE - S.FREIGHT_VALUE
) > 0.01


UNION ALL


SELECT
    'PAYMENT_VALUE',
    COUNT(*)
FROM SILVER.PAYMENTS S
INNER JOIN GOLD.FACT_PAYMENTS G
    ON G.ORDER_ID = S.ORDER_ID
   AND G.PAYMENT_SEQUENTIAL = S.PAYMENT_SEQUENTIAL
WHERE ABS(
    G.PAYMENT_VALUE - S.PAYMENT_VALUE
) > 0.01


UNION ALL


SELECT
    'PAYMENT_TYPE',
    COUNT(*)
FROM SILVER.PAYMENTS S
INNER JOIN GOLD.FACT_PAYMENTS G
    ON G.ORDER_ID = S.ORDER_ID
   AND G.PAYMENT_SEQUENTIAL = S.PAYMENT_SEQUENTIAL
WHERE
       G.PAYMENT_TYPE <> S.PAYMENT_TYPE
    OR (
           G.PAYMENT_TYPE IS NULL
           AND S.PAYMENT_TYPE IS NOT NULL
       )
    OR (
           G.PAYMENT_TYPE IS NOT NULL
           AND S.PAYMENT_TYPE IS NULL
       )


UNION ALL


SELECT
    'PAYMENT_INSTALLMENTS',
    COUNT(*)
FROM SILVER.PAYMENTS S
INNER JOIN GOLD.FACT_PAYMENTS G
    ON G.ORDER_ID = S.ORDER_ID
   AND G.PAYMENT_SEQUENTIAL = S.PAYMENT_SEQUENTIAL
WHERE
       G.PAYMENT_INSTALLMENTS <> S.PAYMENT_INSTALLMENTS
    OR (
           G.PAYMENT_INSTALLMENTS IS NULL
           AND S.PAYMENT_INSTALLMENTS IS NOT NULL
       )
    OR (
           G.PAYMENT_INSTALLMENTS IS NOT NULL
           AND S.PAYMENT_INSTALLMENTS IS NULL
       )


UNION ALL


SELECT
    'REVIEW_SCORE',
    COUNT(*)
FROM SILVER.REVIEWS S
INNER JOIN GOLD.FACT_REVIEWS G
    ON G.REVIEW_ID = S.REVIEW_ID
   AND G.ORDER_ID = S.ORDER_ID
WHERE
       G.REVIEW_SCORE <> S.REVIEW_SCORE
    OR (
           G.REVIEW_SCORE IS NULL
           AND S.REVIEW_SCORE IS NOT NULL
       )
    OR (
           G.REVIEW_SCORE IS NOT NULL
           AND S.REVIEW_SCORE IS NULL
       )


UNION ALL


SELECT
    'FACT_ORDERS_GRAIN',
    COUNT(*)
FROM (
    SELECT ORDER_ID
    FROM GOLD.FACT_ORDERS
    GROUP BY ORDER_ID
    HAVING COUNT(*) > 1
)


UNION ALL


SELECT
    'FACT_ORDER_ITEMS_GRAIN',
    COUNT(*)
FROM (
    SELECT
        ORDER_ID,
        ORDER_ITEM_ID
    FROM GOLD.FACT_ORDER_ITEMS
    GROUP BY
        ORDER_ID,
        ORDER_ITEM_ID
    HAVING COUNT(*) > 1
)


UNION ALL


SELECT
    'FACT_PAYMENTS_GRAIN',
    COUNT(*)
FROM (
    SELECT
        ORDER_ID,
        PAYMENT_SEQUENTIAL
    FROM GOLD.FACT_PAYMENTS
    GROUP BY
        ORDER_ID,
        PAYMENT_SEQUENTIAL
    HAVING COUNT(*) > 1
)


UNION ALL


SELECT
    'FACT_REVIEWS_GRAIN',
    COUNT(*)
FROM (
    SELECT
        REVIEW_ID,
        ORDER_ID
    FROM GOLD.FACT_REVIEWS
    GROUP BY
        REVIEW_ID,
        ORDER_ID
    HAVING COUNT(*) > 1
)

ORDER BY CONTROL_NAME;


-- ============================================================
-- 36. RESULTAT GLOBAL
--
-- PASS si aucun des controles principaux n'a d'erreur.
--
-- Cette requete reprend les controles essentiels
-- dans un seul compteur.
-- ============================================================

SELECT
    CASE
        WHEN TOTAL_ERRORS = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS RECONCILIATION_STATUS,

    TOTAL_ERRORS

FROM (
    SELECT
        (
            -- Customers absents
            (SELECT COUNT(*)
             FROM SILVER.CUSTOMERS S
             WHERE NOT EXISTS (
                 SELECT 1
                 FROM GOLD.DIM_CUSTOMER G
                 WHERE G.CUSTOMER_ID = S.CUSTOMER_ID
             ))

            +

            -- Products absents
            (SELECT COUNT(*)
             FROM SILVER.PRODUCTS S
             WHERE NOT EXISTS (
                 SELECT 1
                 FROM GOLD.DIM_PRODUCT G
                 WHERE G.PRODUCT_ID = S.PRODUCT_ID
             ))

            +

            -- Sellers absents
            (SELECT COUNT(*)
             FROM SILVER.SELLERS S
             WHERE NOT EXISTS (
                 SELECT 1
                 FROM GOLD.DIM_SELLER G
                 WHERE G.SELLER_ID = S.SELLER_ID
             ))

            +

            -- Orders absentes
            (SELECT COUNT(*)
             FROM SILVER.ORDERS S
             WHERE NOT EXISTS (
                 SELECT 1
                 FROM GOLD.FACT_ORDERS G
                 WHERE G.ORDER_ID = S.ORDER_ID
             ))

            +

            -- Items absents
            (SELECT COUNT(*)
             FROM SILVER.ORDER_ITEMS S
             WHERE NOT EXISTS (
                 SELECT 1
                 FROM GOLD.FACT_ORDER_ITEMS G
                 WHERE G.ORDER_ID = S.ORDER_ID
                   AND G.ORDER_ITEM_ID = S.ORDER_ITEM_ID
             ))

            +

            -- Payments absents
            (SELECT COUNT(*)
             FROM SILVER.PAYMENTS S
             WHERE NOT EXISTS (
                 SELECT 1
                 FROM GOLD.FACT_PAYMENTS G
                 WHERE G.ORDER_ID = S.ORDER_ID
                   AND G.PAYMENT_SEQUENTIAL =
                       S.PAYMENT_SEQUENTIAL
             ))

            +

            -- Reviews absents
            (SELECT COUNT(*)
             FROM SILVER.REVIEWS S
             WHERE NOT EXISTS (
                 SELECT 1
                 FROM GOLD.FACT_REVIEWS G
                 WHERE G.REVIEW_ID = S.REVIEW_ID
                   AND G.ORDER_ID = S.ORDER_ID
             ))

            +

            -- Item price incoherent
            (SELECT COUNT(*)
             FROM SILVER.ORDER_ITEMS S
             INNER JOIN GOLD.FACT_ORDER_ITEMS G
                 ON G.ORDER_ID = S.ORDER_ID
                AND G.ORDER_ITEM_ID = S.ORDER_ITEM_ID
             WHERE ABS(G.PRICE - S.PRICE) > 0.01)

            +

            -- Item freight incoherent
            (SELECT COUNT(*)
             FROM SILVER.ORDER_ITEMS S
             INNER JOIN GOLD.FACT_ORDER_ITEMS G
                 ON G.ORDER_ID = S.ORDER_ID
                AND G.ORDER_ITEM_ID = S.ORDER_ITEM_ID
             WHERE ABS(
                 G.FREIGHT_VALUE - S.FREIGHT_VALUE
             ) > 0.01)

            +

            -- Payment value incoherent
            (SELECT COUNT(*)
             FROM SILVER.PAYMENTS S
             INNER JOIN GOLD.FACT_PAYMENTS G
                 ON G.ORDER_ID = S.ORDER_ID
                AND G.PAYMENT_SEQUENTIAL =
                    S.PAYMENT_SEQUENTIAL
             WHERE ABS(
                 G.PAYMENT_VALUE - S.PAYMENT_VALUE
             ) > 0.01)

            +

            -- Review score incoherent
            (SELECT COUNT(*)
             FROM SILVER.REVIEWS S
             INNER JOIN GOLD.FACT_REVIEWS G
                 ON G.REVIEW_ID = S.REVIEW_ID
                AND G.ORDER_ID = S.ORDER_ID
             WHERE G.REVIEW_SCORE <> S.REVIEW_SCORE)

        ) AS TOTAL_ERRORS

    FROM DUAL
);


-- ============================================================
-- FIN
-- 13_reconcile_silver_gold.sql
-- ============================================================