-- ============================================================
-- MODERN DATA PLATFORM - OLIST
-- GOLD
-- 14_gold_kpi_checks.sql
--
-- KPI METIER + CONTROLES DE COHERENCE
--
-- Preconditions :
-- 11_audit_gold.sql              OK
-- 12_validate_gold_measures.sql  OK
-- 13_reconcile_silver_gold.sql   PASS / 0
--
-- Ce script ne modifie aucune donnee.
-- ============================================================


-- ============================================================
-- PARTIE A - COMMANDES
-- ============================================================


-- 1. TOTAL COMMANDES

SELECT
    COUNT(*) AS TOTAL_ORDERS
FROM GOLD.FACT_ORDERS;


-- 2. REPARTITION PAR STATUT

SELECT
    ORDER_STATUS,
    COUNT(*) AS NB_ORDERS,
    ROUND(
        COUNT(*) * 100 /
        (SELECT COUNT(*) FROM GOLD.FACT_ORDERS),
        2
    ) AS PCT_ORDERS
FROM GOLD.FACT_ORDERS
GROUP BY ORDER_STATUS
ORDER BY NB_ORDERS DESC;


-- 3. COMMANDES LIVREES

SELECT
    COUNT(*) AS DELIVERED_ORDERS
FROM GOLD.FACT_ORDERS
WHERE ORDER_STATUS = 'delivered';


-- ============================================================
-- PARTIE B - VENTES
-- ============================================================


-- 4. VALEURS ARTICLES

SELECT
    ROUND(SUM(PRICE), 2)
        AS TOTAL_PRODUCT_VALUE,

    ROUND(SUM(FREIGHT_VALUE), 2)
        AS TOTAL_FREIGHT_VALUE,

    ROUND(SUM(TOTAL_ITEM_VALUE), 2)
        AS TOTAL_ORDER_ITEM_VALUE
FROM GOLD.FACT_ORDER_ITEMS;


-- 5. TOTAL PAIEMENTS

SELECT
    ROUND(SUM(PAYMENT_VALUE), 2)
        AS TOTAL_PAYMENT_VALUE
FROM GOLD.FACT_PAYMENTS;


-- 6. PANIER MOYEN

SELECT
    ROUND(AVG(ORDER_VALUE), 2)
        AS AVG_ORDER_VALUE,

    ROUND(MIN(ORDER_VALUE), 2)
        AS MIN_ORDER_VALUE,

    ROUND(MAX(ORDER_VALUE), 2)
        AS MAX_ORDER_VALUE
FROM (
    SELECT
        ORDER_ID,
        SUM(TOTAL_ITEM_VALUE) AS ORDER_VALUE
    FROM GOLD.FACT_ORDER_ITEMS
    GROUP BY ORDER_ID
);


-- 7. PRIX ARTICLE

SELECT
    ROUND(AVG(PRICE), 2)
        AS AVG_ITEM_PRICE,

    MIN(PRICE)
        AS MIN_ITEM_PRICE,

    MAX(PRICE)
        AS MAX_ITEM_PRICE
FROM GOLD.FACT_ORDER_ITEMS;


-- 8. FREIGHT MOYEN

SELECT
    ROUND(AVG(FREIGHT_VALUE), 2)
        AS AVG_FREIGHT_VALUE,

    MIN(FREIGHT_VALUE)
        AS MIN_FREIGHT_VALUE,

    MAX(FREIGHT_VALUE)
        AS MAX_FREIGHT_VALUE
FROM GOLD.FACT_ORDER_ITEMS;


-- ============================================================
-- 9. PART DU FREIGHT
--
-- Sous-requete volontairement utilisee pour Oracle.
-- ============================================================

SELECT
    TOTAL_FREIGHT,
    TOTAL_VALUE,

    ROUND(
        (TOTAL_FREIGHT / TOTAL_VALUE) * 100,
        2
    ) AS FREIGHT_PCT

FROM (
    SELECT
        SUM(FREIGHT_VALUE)
            AS TOTAL_FREIGHT,

        SUM(TOTAL_ITEM_VALUE)
            AS TOTAL_VALUE

    FROM GOLD.FACT_ORDER_ITEMS
);


-- ============================================================
-- PARTIE C - ARTICLES
-- ============================================================


-- 10. TOTAL ARTICLES

SELECT
    COUNT(*) AS TOTAL_ITEMS
FROM GOLD.FACT_ORDER_ITEMS;


-- 11. ARTICLES PAR COMMANDE

SELECT
    ROUND(AVG(NB_ITEMS), 2)
        AS AVG_ITEMS_PER_ORDER,

    MIN(NB_ITEMS)
        AS MIN_ITEMS_PER_ORDER,

    MAX(NB_ITEMS)
        AS MAX_ITEMS_PER_ORDER

FROM (
    SELECT
        ORDER_ID,
        COUNT(*) AS NB_ITEMS
    FROM GOLD.FACT_ORDER_ITEMS
    GROUP BY ORDER_ID
);


-- 12. COMMANDES MULTI-ARTICLES

SELECT
    COUNT(*) AS MULTI_ITEM_ORDERS
FROM (
    SELECT ORDER_ID
    FROM GOLD.FACT_ORDER_ITEMS
    GROUP BY ORDER_ID
    HAVING COUNT(*) > 1
);


-- ============================================================
-- PARTIE D - PAIEMENTS
-- ============================================================


-- 13. PAIEMENTS PAR TYPE

SELECT
    PAYMENT_TYPE,

    COUNT(*) AS NB_PAYMENTS,

    ROUND(
        COUNT(*) * 100 /
        (SELECT COUNT(*) FROM GOLD.FACT_PAYMENTS),
        2
    ) AS PCT_PAYMENTS,

    ROUND(
        SUM(PAYMENT_VALUE),
        2
    ) AS TOTAL_PAYMENT_VALUE,

    ROUND(
        AVG(PAYMENT_VALUE),
        2
    ) AS AVG_PAYMENT_VALUE

FROM GOLD.FACT_PAYMENTS
GROUP BY PAYMENT_TYPE
ORDER BY NB_PAYMENTS DESC;


-- 14. MENSUALITES

SELECT
    ROUND(
        AVG(PAYMENT_INSTALLMENTS),
        2
    ) AS AVG_INSTALLMENTS,

    MIN(PAYMENT_INSTALLMENTS)
        AS MIN_INSTALLMENTS,

    MAX(PAYMENT_INSTALLMENTS)
        AS MAX_INSTALLMENTS

FROM GOLD.FACT_PAYMENTS;


-- 15. COMMANDES MULTI-PAIEMENTS

SELECT
    COUNT(*) AS MULTI_PAYMENT_ORDERS

FROM (
    SELECT ORDER_ID
    FROM GOLD.FACT_PAYMENTS
    GROUP BY ORDER_ID
    HAVING COUNT(*) > 1
);


-- ============================================================
-- PARTIE E - LIVRAISON
-- ============================================================


-- 16. DELAI MOYEN DE LIVRAISON

SELECT
    COUNT(DELIVERY_DAYS)
        AS ORDERS_WITH_DELIVERY,

    ROUND(
        AVG(DELIVERY_DAYS),
        2
    ) AS AVG_DELIVERY_DAYS,

    MIN(DELIVERY_DAYS)
        AS MIN_DELIVERY_DAYS,

    MAX(DELIVERY_DAYS)
        AS MAX_DELIVERY_DAYS

FROM GOLD.FACT_ORDERS;


-- 17. ECART PAR RAPPORT A LA DATE ESTIMEE

SELECT
    COUNT(DELIVERY_DELAY_DAYS)
        AS ORDERS_WITH_DELAY_INFO,

    ROUND(
        AVG(DELIVERY_DELAY_DAYS),
        2
    ) AS AVG_DELIVERY_DELAY,

    MIN(DELIVERY_DELAY_DAYS)
        AS MIN_DELIVERY_DELAY,

    MAX(DELIVERY_DELAY_DAYS)
        AS MAX_DELIVERY_DELAY

FROM GOLD.FACT_ORDERS;


-- ============================================================
-- 18. TAUX DE RETARD
--
-- Calcul en deux niveaux pour rester simple pour Oracle.
-- ============================================================

SELECT
    LATE_ORDERS,
    ON_TIME_ORDERS,
    UNKNOWN_ORDERS,

    CASE
        WHEN KNOWN_ORDERS = 0
        THEN NULL
        ELSE ROUND(
            (LATE_ORDERS / KNOWN_ORDERS) * 100,
            2
        )
    END AS LATE_DELIVERY_RATE

FROM (
    SELECT
        SUM(
            CASE
                WHEN IS_LATE_DELIVERY = 1 THEN 1
                ELSE 0
            END
        ) AS LATE_ORDERS,

        SUM(
            CASE
                WHEN IS_LATE_DELIVERY = 0 THEN 1
                ELSE 0
            END
        ) AS ON_TIME_ORDERS,

        SUM(
            CASE
                WHEN IS_LATE_DELIVERY IS NULL THEN 1
                ELSE 0
            END
        ) AS UNKNOWN_ORDERS,

        SUM(
            CASE
                WHEN IS_LATE_DELIVERY IS NOT NULL THEN 1
                ELSE 0
            END
        ) AS KNOWN_ORDERS

    FROM GOLD.FACT_ORDERS
);


-- 19. RETARD MOYEN DES COMMANDES EN RETARD

SELECT
    COUNT(*) AS LATE_ORDERS,

    ROUND(
        AVG(DELIVERY_DELAY_DAYS),
        2
    ) AS AVG_LATE_DAYS,

    MIN(DELIVERY_DELAY_DAYS)
        AS MIN_LATE_DAYS,

    MAX(DELIVERY_DELAY_DAYS)
        AS MAX_LATE_DAYS

FROM GOLD.FACT_ORDERS
WHERE IS_LATE_DELIVERY = 1;


-- ============================================================
-- PARTIE F - SATISFACTION
-- ============================================================


-- 20. SCORE MOYEN

SELECT
    COUNT(*) AS NB_REVIEWS,

    ROUND(
        AVG(REVIEW_SCORE),
        2
    ) AS AVG_REVIEW_SCORE,

    MIN(REVIEW_SCORE)
        AS MIN_REVIEW_SCORE,

    MAX(REVIEW_SCORE)
        AS MAX_REVIEW_SCORE

FROM GOLD.FACT_REVIEWS;


-- 21. DISTRIBUTION DES SCORES

SELECT
    REVIEW_SCORE,

    COUNT(*) AS NB_REVIEWS,

    ROUND(
        COUNT(*) * 100 /
        (SELECT COUNT(*) FROM GOLD.FACT_REVIEWS),
        2
    ) AS PCT_REVIEWS

FROM GOLD.FACT_REVIEWS
GROUP BY REVIEW_SCORE
ORDER BY REVIEW_SCORE;


-- ============================================================
-- 22. TAUX AVIS POSITIFS
--
-- Positif = score 4 ou 5.
-- ============================================================

SELECT
    TOTAL_REVIEWS,
    POSITIVE_REVIEWS,

    CASE
        WHEN TOTAL_REVIEWS = 0
        THEN NULL
        ELSE ROUND(
            (POSITIVE_REVIEWS / TOTAL_REVIEWS) * 100,
            2
        )
    END AS POSITIVE_REVIEW_RATE

FROM (
    SELECT
        COUNT(*) AS TOTAL_REVIEWS,

        SUM(
            CASE
                WHEN REVIEW_SCORE >= 4 THEN 1
                ELSE 0
            END
        ) AS POSITIVE_REVIEWS

    FROM GOLD.FACT_REVIEWS
);


-- ============================================================
-- 23. TAUX AVIS NEGATIFS
--
-- Negatif = score 1 ou 2.
-- ============================================================

SELECT
    TOTAL_REVIEWS,
    NEGATIVE_REVIEWS,

    CASE
        WHEN TOTAL_REVIEWS = 0
        THEN NULL
        ELSE ROUND(
            (NEGATIVE_REVIEWS / TOTAL_REVIEWS) * 100,
            2
        )
    END AS NEGATIVE_REVIEW_RATE

FROM (
    SELECT
        COUNT(*) AS TOTAL_REVIEWS,

        SUM(
            CASE
                WHEN REVIEW_SCORE <= 2 THEN 1
                ELSE 0
            END
        ) AS NEGATIVE_REVIEWS

    FROM GOLD.FACT_REVIEWS
);


-- ============================================================
-- PARTIE G - LIVRAISON VS SATISFACTION
-- ============================================================


-- 24. SCORE MOYEN SELON LIVRAISON

SELECT
    CASE
        WHEN O.IS_LATE_DELIVERY = 1
        THEN 'LATE'

        WHEN O.IS_LATE_DELIVERY = 0
        THEN 'ON_TIME_OR_EARLY'

        ELSE 'NOT_AVAILABLE'
    END AS DELIVERY_STATUS,

    COUNT(*) AS NB_REVIEWS,

    ROUND(
        AVG(R.REVIEW_SCORE),
        2
    ) AS AVG_REVIEW_SCORE

FROM GOLD.FACT_REVIEWS R

INNER JOIN GOLD.FACT_ORDERS O
    ON O.ORDER_ID = R.ORDER_ID

GROUP BY
    CASE
        WHEN O.IS_LATE_DELIVERY = 1
        THEN 'LATE'

        WHEN O.IS_LATE_DELIVERY = 0
        THEN 'ON_TIME_OR_EARLY'

        ELSE 'NOT_AVAILABLE'
    END

ORDER BY DELIVERY_STATUS;


-- ============================================================
-- 25. AVIS NEGATIFS SELON LIVRAISON
-- ============================================================

SELECT
    DELIVERY_STATUS,
    NB_REVIEWS,
    NEGATIVE_REVIEWS,

    CASE
        WHEN NB_REVIEWS = 0
        THEN NULL
        ELSE ROUND(
            (NEGATIVE_REVIEWS / NB_REVIEWS) * 100,
            2
        )
    END AS NEGATIVE_REVIEW_RATE

FROM (
    SELECT
        CASE
            WHEN O.IS_LATE_DELIVERY = 1
            THEN 'LATE'

            WHEN O.IS_LATE_DELIVERY = 0
            THEN 'ON_TIME_OR_EARLY'

            ELSE 'NOT_AVAILABLE'
        END AS DELIVERY_STATUS,

        COUNT(*) AS NB_REVIEWS,

        SUM(
            CASE
                WHEN R.REVIEW_SCORE <= 2 THEN 1
                ELSE 0
            END
        ) AS NEGATIVE_REVIEWS

    FROM GOLD.FACT_REVIEWS R

    INNER JOIN GOLD.FACT_ORDERS O
        ON O.ORDER_ID = R.ORDER_ID

    GROUP BY
        CASE
            WHEN O.IS_LATE_DELIVERY = 1
            THEN 'LATE'

            WHEN O.IS_LATE_DELIVERY = 0
            THEN 'ON_TIME_OR_EARLY'

            ELSE 'NOT_AVAILABLE'
        END
)

ORDER BY DELIVERY_STATUS;


-- ============================================================
-- PARTIE H - EVOLUTION TEMPORELLE
-- ============================================================


-- 26. COMMANDES PAR MOIS

SELECT
    D.YEAR_NUMBER,
    D.MONTH_NUMBER,
    COUNT(*) AS NB_ORDERS

FROM GOLD.FACT_ORDERS O

INNER JOIN GOLD.DIM_DATE D
    ON D.DATE_KEY = O.PURCHASE_DATE_KEY

GROUP BY
    D.YEAR_NUMBER,
    D.MONTH_NUMBER

ORDER BY
    D.YEAR_NUMBER,
    D.MONTH_NUMBER;


-- 27. VENTES PAR MOIS

SELECT
    D.YEAR_NUMBER,
    D.MONTH_NUMBER,

    COUNT(DISTINCT I.ORDER_ID)
        AS NB_ORDERS,

    COUNT(*) AS NB_ITEMS,

    ROUND(
        SUM(I.PRICE),
        2
    ) AS PRODUCT_VALUE,

    ROUND(
        SUM(I.FREIGHT_VALUE),
        2
    ) AS FREIGHT_VALUE,

    ROUND(
        SUM(I.TOTAL_ITEM_VALUE),
        2
    ) AS TOTAL_VALUE

FROM GOLD.FACT_ORDER_ITEMS I

INNER JOIN GOLD.DIM_DATE D
    ON D.DATE_KEY = I.PURCHASE_DATE_KEY

GROUP BY
    D.YEAR_NUMBER,
    D.MONTH_NUMBER

ORDER BY
    D.YEAR_NUMBER,
    D.MONTH_NUMBER;


-- 28. PAIEMENTS PAR MOIS

SELECT
    D.YEAR_NUMBER,
    D.MONTH_NUMBER,

    COUNT(DISTINCT P.ORDER_ID)
        AS NB_ORDERS,

    COUNT(*) AS NB_PAYMENTS,

    ROUND(
        SUM(P.PAYMENT_VALUE),
        2
    ) AS PAYMENT_VALUE

FROM GOLD.FACT_PAYMENTS P

INNER JOIN GOLD.DIM_DATE D
    ON D.DATE_KEY = P.PURCHASE_DATE_KEY

GROUP BY
    D.YEAR_NUMBER,
    D.MONTH_NUMBER

ORDER BY
    D.YEAR_NUMBER,
    D.MONTH_NUMBER;


-- 29. REVIEWS PAR MOIS

SELECT
    D.YEAR_NUMBER,
    D.MONTH_NUMBER,

    COUNT(*) AS NB_REVIEWS,

    ROUND(
        AVG(R.REVIEW_SCORE),
        2
    ) AS AVG_REVIEW_SCORE

FROM GOLD.FACT_REVIEWS R

INNER JOIN GOLD.DIM_DATE D
    ON D.DATE_KEY = R.REVIEW_DATE_KEY

GROUP BY
    D.YEAR_NUMBER,
    D.MONTH_NUMBER

ORDER BY
    D.YEAR_NUMBER,
    D.MONTH_NUMBER;


-- ============================================================
-- PARTIE I - PRODUITS
-- ============================================================


-- 30. TOP 10 PRODUITS PAR NOMBRE D'ARTICLES

SELECT *
FROM (
    SELECT
        P.PRODUCT_ID,

        COUNT(*) AS NB_ITEMS,

        COUNT(DISTINCT I.ORDER_ID)
            AS NB_ORDERS,

        ROUND(
            SUM(I.PRICE),
            2
        ) AS PRODUCT_VALUE,

        ROUND(
            SUM(I.TOTAL_ITEM_VALUE),
            2
        ) AS TOTAL_VALUE

    FROM GOLD.FACT_ORDER_ITEMS I

    INNER JOIN GOLD.DIM_PRODUCT P
        ON P.PRODUCT_KEY = I.PRODUCT_KEY

    GROUP BY
        P.PRODUCT_ID

    ORDER BY NB_ITEMS DESC
)
WHERE ROWNUM <= 10;


-- 31. TOP 10 PRODUITS PAR VALEUR

SELECT *
FROM (
    SELECT
        P.PRODUCT_ID,

        COUNT(*) AS NB_ITEMS,

        ROUND(
            SUM(I.PRICE),
            2
        ) AS PRODUCT_VALUE

    FROM GOLD.FACT_ORDER_ITEMS I

    INNER JOIN GOLD.DIM_PRODUCT P
        ON P.PRODUCT_KEY = I.PRODUCT_KEY

    GROUP BY
        P.PRODUCT_ID

    ORDER BY PRODUCT_VALUE DESC
)
WHERE ROWNUM <= 10;


-- ============================================================
-- PARTIE J - VENDEURS
-- ============================================================


-- 32. TOP 10 VENDEURS PAR ARTICLES

SELECT *
FROM (
    SELECT
        S.SELLER_ID,

        COUNT(*) AS NB_ITEMS,

        COUNT(DISTINCT I.ORDER_ID)
            AS NB_ORDERS,

        ROUND(
            SUM(I.PRICE),
            2
        ) AS PRODUCT_VALUE

    FROM GOLD.FACT_ORDER_ITEMS I

    INNER JOIN GOLD.DIM_SELLER S
        ON S.SELLER_KEY = I.SELLER_KEY

    GROUP BY
        S.SELLER_ID

    ORDER BY NB_ITEMS DESC
)
WHERE ROWNUM <= 10;


-- 33. TOP 10 VENDEURS PAR VALEUR

SELECT *
FROM (
    SELECT
        S.SELLER_ID,

        COUNT(DISTINCT I.ORDER_ID)
            AS NB_ORDERS,

        COUNT(*) AS NB_ITEMS,

        ROUND(
            SUM(I.PRICE),
            2
        ) AS PRODUCT_VALUE,

        ROUND(
            SUM(I.TOTAL_ITEM_VALUE),
            2
        ) AS TOTAL_VALUE

    FROM GOLD.FACT_ORDER_ITEMS I

    INNER JOIN GOLD.DIM_SELLER S
        ON S.SELLER_KEY = I.SELLER_KEY

    GROUP BY
        S.SELLER_ID

    ORDER BY PRODUCT_VALUE DESC
)
WHERE ROWNUM <= 10;


-- ============================================================
-- PARTIE K - GEOGRAPHIE VENDEURS
-- ============================================================


-- 34. VENTES PAR ETAT VENDEUR

SELECT
    G.STATE,

    COUNT(DISTINCT I.ORDER_ID)
        AS NB_ORDERS,

    COUNT(*) AS NB_ITEMS,

    COUNT(DISTINCT I.SELLER_KEY)
        AS NB_SELLERS,

    ROUND(
        SUM(I.PRICE),
        2
    ) AS PRODUCT_VALUE,

    ROUND(
        SUM(I.FREIGHT_VALUE),
        2
    ) AS FREIGHT_VALUE,

    ROUND(
        SUM(I.TOTAL_ITEM_VALUE),
        2
    ) AS TOTAL_VALUE

FROM GOLD.FACT_ORDER_ITEMS I

INNER JOIN GOLD.DIM_SELLER S
    ON S.SELLER_KEY = I.SELLER_KEY

INNER JOIN GOLD.DIM_GEOGRAPHY G
    ON G.GEOGRAPHY_KEY = S.GEOGRAPHY_KEY

GROUP BY
    G.STATE

ORDER BY PRODUCT_VALUE DESC;


-- ============================================================
-- PARTIE L - CLIENTS
-- ============================================================


-- 35. CLIENTS AVEC COMMANDE

SELECT
    COUNT(DISTINCT CUSTOMER_KEY)
        AS CUSTOMERS_WITH_ORDER
FROM GOLD.FACT_ORDERS;


-- 36. COMMANDES PAR CLIENT

SELECT
    ROUND(
        AVG(NB_ORDERS),
        2
    ) AS AVG_ORDERS_PER_CUSTOMER,

    MIN(NB_ORDERS)
        AS MIN_ORDERS_PER_CUSTOMER,

    MAX(NB_ORDERS)
        AS MAX_ORDERS_PER_CUSTOMER

FROM (
    SELECT
        CUSTOMER_KEY,
        COUNT(*) AS NB_ORDERS
    FROM GOLD.FACT_ORDERS
    GROUP BY CUSTOMER_KEY
);


-- ============================================================
-- PARTIE M - KPI GLOBAL
-- ============================================================


-- ============================================================
-- 37. TABLEAU DE BORD PRINCIPAL
--
-- Les KPI sont calcules independamment.
-- Aucun risque de multiplication entre tables de faits.
-- ============================================================

SELECT
    (SELECT COUNT(*)
     FROM GOLD.FACT_ORDERS)
        AS TOTAL_ORDERS,

    (SELECT COUNT(*)
     FROM GOLD.FACT_ORDER_ITEMS)
        AS TOTAL_ITEMS,

    (SELECT COUNT(*)
     FROM GOLD.FACT_PAYMENTS)
        AS TOTAL_PAYMENTS,

    (SELECT COUNT(*)
     FROM GOLD.FACT_REVIEWS)
        AS TOTAL_REVIEWS,

    (SELECT ROUND(SUM(PRICE), 2)
     FROM GOLD.FACT_ORDER_ITEMS)
        AS TOTAL_PRODUCT_VALUE,

    (SELECT ROUND(SUM(FREIGHT_VALUE), 2)
     FROM GOLD.FACT_ORDER_ITEMS)
        AS TOTAL_FREIGHT_VALUE,

    (SELECT ROUND(SUM(TOTAL_ITEM_VALUE), 2)
     FROM GOLD.FACT_ORDER_ITEMS)
        AS TOTAL_ITEM_VALUE,

    (SELECT ROUND(SUM(PAYMENT_VALUE), 2)
     FROM GOLD.FACT_PAYMENTS)
        AS TOTAL_PAYMENT_VALUE,

    (
        SELECT
            ROUND(
                AVG(ORDER_VALUE),
                2
            )
        FROM (
            SELECT
                ORDER_ID,
                SUM(TOTAL_ITEM_VALUE) AS ORDER_VALUE
            FROM GOLD.FACT_ORDER_ITEMS
            GROUP BY ORDER_ID
        )
    ) AS AVG_ORDER_VALUE,

    (SELECT ROUND(AVG(DELIVERY_DAYS), 2)
     FROM GOLD.FACT_ORDERS)
        AS AVG_DELIVERY_DAYS,

    (SELECT ROUND(AVG(REVIEW_SCORE), 2)
     FROM GOLD.FACT_REVIEWS)
        AS AVG_REVIEW_SCORE

FROM DUAL;


-- ============================================================
-- PARTIE N - CONTROLES KPI
-- ============================================================


-- 38. TOTAL PAR STATUT

SELECT
    (SELECT COUNT(*)
     FROM GOLD.FACT_ORDERS)
        AS TOTAL_ORDERS,

    (SELECT SUM(NB_ROWS)
     FROM (
        SELECT
            ORDER_STATUS,
            COUNT(*) AS NB_ROWS
        FROM GOLD.FACT_ORDERS
        GROUP BY ORDER_STATUS
     ))
        AS TOTAL_BY_STATUS

FROM DUAL;


-- 39. TOTAL PAR SCORE

SELECT
    (SELECT COUNT(*)
     FROM GOLD.FACT_REVIEWS)
        AS TOTAL_REVIEWS,

    (SELECT SUM(NB_ROWS)
     FROM (
        SELECT
            REVIEW_SCORE,
            COUNT(*) AS NB_ROWS
        FROM GOLD.FACT_REVIEWS
        GROUP BY REVIEW_SCORE
     ))
        AS TOTAL_BY_SCORE

FROM DUAL;


-- 40. TOTAL PAR TYPE DE PAIEMENT

SELECT
    (SELECT COUNT(*)
     FROM GOLD.FACT_PAYMENTS)
        AS TOTAL_PAYMENTS,

    (SELECT SUM(NB_ROWS)
     FROM (
        SELECT
            PAYMENT_TYPE,
            COUNT(*) AS NB_ROWS
        FROM GOLD.FACT_PAYMENTS
        GROUP BY PAYMENT_TYPE
     ))
        AS TOTAL_BY_TYPE

FROM DUAL;


-- 41. CONTROLE TOTAL ITEM

SELECT
    ROUND(
        SUM(PRICE) + SUM(FREIGHT_VALUE),
        2
    ) AS CALCULATED_TOTAL,

    ROUND(
        SUM(TOTAL_ITEM_VALUE),
        2
    ) AS STORED_TOTAL,

    ROUND(
        SUM(TOTAL_ITEM_VALUE)
        -
        SUM(PRICE)
        -
        SUM(FREIGHT_VALUE),
        2
    ) AS DIFFERENCE

FROM GOLD.FACT_ORDER_ITEMS;


-- ============================================================
-- 42. CONTROLE FINAL
--
-- Tous les ERROR_COUNT doivent etre 0.
-- ============================================================

SELECT
    'ORDER_ITEM_TOTAL' AS CONTROL_NAME,
    COUNT(*) AS ERROR_COUNT

FROM GOLD.FACT_ORDER_ITEMS

WHERE ABS(
    TOTAL_ITEM_VALUE - PRICE - FREIGHT_VALUE
) > 0.01


UNION ALL


SELECT
    'DELIVERY_FLAG',
    COUNT(*)

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
       )


UNION ALL


SELECT
    'ORDER_STATUS_TOTAL',

    ABS(
        (SELECT COUNT(*)
         FROM GOLD.FACT_ORDERS)
        -
        (SELECT SUM(NB_ROWS)
         FROM (
             SELECT
                 ORDER_STATUS,
                 COUNT(*) AS NB_ROWS
             FROM GOLD.FACT_ORDERS
             GROUP BY ORDER_STATUS
         ))
    )

FROM DUAL


UNION ALL


SELECT
    'PAYMENT_TYPE_TOTAL',

    ABS(
        (SELECT COUNT(*)
         FROM GOLD.FACT_PAYMENTS)
        -
        (SELECT SUM(NB_ROWS)
         FROM (
             SELECT
                 PAYMENT_TYPE,
                 COUNT(*) AS NB_ROWS
             FROM GOLD.FACT_PAYMENTS
             GROUP BY PAYMENT_TYPE
         ))
    )

FROM DUAL


UNION ALL


SELECT
    'REVIEW_SCORE_TOTAL',

    ABS(
        (SELECT COUNT(*)
         FROM GOLD.FACT_REVIEWS)
        -
        (SELECT SUM(NB_ROWS)
         FROM (
             SELECT
                 REVIEW_SCORE,
                 COUNT(*) AS NB_ROWS
             FROM GOLD.FACT_REVIEWS
             GROUP BY REVIEW_SCORE
         ))
    )

FROM DUAL

ORDER BY CONTROL_NAME;


-- ============================================================
-- FIN
-- 14_gold_kpi_checks.sql
-- ============================================================