-- ============================================================
-- MODERN DATA PLATFORM - OLIST
-- GOLD
-- 12_validate_gold_measures.sql
--
-- VALIDATION DES MESURES METIER DE LA COUCHE GOLD
--
-- Tables controlees :
-- FACT_ORDERS
-- FACT_ORDER_ITEMS
-- FACT_PAYMENTS
-- FACT_REVIEWS
--
-- Ce script ne modifie aucune donnee.
-- ============================================================


-- ============================================================
-- PARTIE A - FACT_ORDERS
-- ============================================================


-- 1. DELIVERY_DAYS NEGATIFS
-- Attendu : 0

SELECT
    COUNT(*) AS DELIVERY_DAYS_NEGATIFS
FROM GOLD.FACT_ORDERS
WHERE DELIVERY_DAYS < 0;


-- ============================================================
-- 2. COHERENCE DELIVERY_DAYS
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS DELIVERY_DAYS_INCOHERENTS
FROM GOLD.FACT_ORDERS
WHERE
       (
           ORDER_DELIVERED_CUSTOMER_DATE IS NULL
           AND DELIVERY_DAYS IS NOT NULL
       )
    OR (
           ORDER_DELIVERED_CUSTOMER_DATE IS NOT NULL
           AND DELIVERY_DAYS IS NULL
       );


-- ============================================================
-- 3. VALIDATION DU CALCUL DELIVERY_DAYS
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS DELIVERY_DAYS_CALCUL_INCORRECT
FROM GOLD.FACT_ORDERS
WHERE ORDER_DELIVERED_CUSTOMER_DATE IS NOT NULL
  AND DELIVERY_DAYS <>
      (
          TRUNC(CAST(ORDER_DELIVERED_CUSTOMER_DATE AS DATE))
          -
          TRUNC(CAST(ORDER_PURCHASE_TIMESTAMP AS DATE))
      );


-- ============================================================
-- 4. VALIDATION DU CALCUL DELIVERY_DELAY_DAYS
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS DELIVERY_DELAY_CALCUL_INCORRECT
FROM GOLD.FACT_ORDERS
WHERE ORDER_DELIVERED_CUSTOMER_DATE IS NOT NULL
  AND ORDER_ESTIMATED_DELIVERY_DATE IS NOT NULL
  AND DELIVERY_DELAY_DAYS <>
      (
          TRUNC(CAST(ORDER_DELIVERED_CUSTOMER_DATE AS DATE))
          -
          TRUNC(CAST(ORDER_ESTIMATED_DELIVERY_DATE AS DATE))
      );


-- ============================================================
-- 5. COHERENCE NULL DE DELIVERY_DELAY_DAYS
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS DELIVERY_DELAY_NULL_INCOHERENT
FROM GOLD.FACT_ORDERS
WHERE
       (
           (
               ORDER_DELIVERED_CUSTOMER_DATE IS NULL
               OR ORDER_ESTIMATED_DELIVERY_DATE IS NULL
           )
           AND DELIVERY_DELAY_DAYS IS NOT NULL
       )
    OR (
           ORDER_DELIVERED_CUSTOMER_DATE IS NOT NULL
           AND ORDER_ESTIMATED_DELIVERY_DATE IS NOT NULL
           AND DELIVERY_DELAY_DAYS IS NULL
       );


-- ============================================================
-- 6. IS_LATE_DELIVERY INVALIDE
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS LATE_FLAG_INVALIDE
FROM GOLD.FACT_ORDERS
WHERE IS_LATE_DELIVERY IS NOT NULL
  AND IS_LATE_DELIVERY NOT IN (0, 1);


-- ============================================================
-- 7. DELAY > 0 MAIS FLAG DIFFERENT DE 1
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS RETARD_FLAG_INCOHERENT
FROM GOLD.FACT_ORDERS
WHERE DELIVERY_DELAY_DAYS > 0
  AND NVL(IS_LATE_DELIVERY, -1) <> 1;


-- ============================================================
-- 8. DELAY <= 0 MAIS FLAG DIFFERENT DE 0
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS NON_RETARD_FLAG_INCOHERENT
FROM GOLD.FACT_ORDERS
WHERE DELIVERY_DELAY_DAYS <= 0
  AND NVL(IS_LATE_DELIVERY, -1) <> 0;


-- ============================================================
-- 9. DELAY NULL MAIS FLAG NON NULL
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS DELAY_NULL_FLAG_NON_NULL
FROM GOLD.FACT_ORDERS
WHERE DELIVERY_DELAY_DAYS IS NULL
  AND IS_LATE_DELIVERY IS NOT NULL;


-- ============================================================
-- 10. DELAY NON NULL MAIS FLAG NULL
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS DELAY_NON_NULL_FLAG_NULL
FROM GOLD.FACT_ORDERS
WHERE DELIVERY_DELAY_DAYS IS NOT NULL
  AND IS_LATE_DELIVERY IS NULL;


-- ============================================================
-- 11. CONTROLE GLOBAL LIVRAISON
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS TOTAL_ERREURS_LIVRAISON
FROM GOLD.FACT_ORDERS
WHERE
       DELIVERY_DAYS < 0

    OR (
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
-- 12. STATISTIQUES DE LIVRAISON
-- ============================================================

SELECT
    COUNT(*) AS TOTAL_ORDERS,

    COUNT(DELIVERY_DAYS) AS ORDERS_AVEC_DELIVERY,

    ROUND(AVG(DELIVERY_DAYS), 2)
        AS AVG_DELIVERY_DAYS,

    MIN(DELIVERY_DAYS)
        AS MIN_DELIVERY_DAYS,

    MAX(DELIVERY_DAYS)
        AS MAX_DELIVERY_DAYS,

    ROUND(AVG(DELIVERY_DELAY_DAYS), 2)
        AS AVG_DELIVERY_DELAY,

    MIN(DELIVERY_DELAY_DAYS)
        AS MIN_DELIVERY_DELAY,

    MAX(DELIVERY_DELAY_DAYS)
        AS MAX_DELIVERY_DELAY

FROM GOLD.FACT_ORDERS;


-- ============================================================
-- 13. REPARTITION RETARD
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
-- PARTIE B - FACT_ORDER_ITEMS
-- ============================================================


-- 14. PRICE NULL
-- Attendu : 0

SELECT
    COUNT(*) AS PRICE_NULL
FROM GOLD.FACT_ORDER_ITEMS
WHERE PRICE IS NULL;


-- 15. PRICE INVALIDE
-- Attendu : 0

SELECT
    COUNT(*) AS PRICE_INVALIDE
FROM GOLD.FACT_ORDER_ITEMS
WHERE PRICE <= 0;


-- 16. FREIGHT NULL
-- Attendu : 0

SELECT
    COUNT(*) AS FREIGHT_NULL
FROM GOLD.FACT_ORDER_ITEMS
WHERE FREIGHT_VALUE IS NULL;


-- 17. FREIGHT NEGATIF
-- Attendu : 0

SELECT
    COUNT(*) AS FREIGHT_NEGATIF
FROM GOLD.FACT_ORDER_ITEMS
WHERE FREIGHT_VALUE < 0;


-- 18. TOTAL_ITEM_VALUE NULL
-- Attendu : 0

SELECT
    COUNT(*) AS TOTAL_ITEM_VALUE_NULL
FROM GOLD.FACT_ORDER_ITEMS
WHERE TOTAL_ITEM_VALUE IS NULL;


-- ============================================================
-- 19. COHERENCE TOTAL_ITEM_VALUE
--
-- TOTAL_ITEM_VALUE = PRICE + FREIGHT_VALUE
--
-- Attendu : 0
-- ============================================================

SELECT
    COUNT(*) AS TOTAL_ITEM_VALUE_INCOHERENT
FROM GOLD.FACT_ORDER_ITEMS
WHERE ABS(
    TOTAL_ITEM_VALUE - (PRICE + FREIGHT_VALUE)
) > 0.01;


-- ============================================================
-- 20. SYNTHESE ORDER_ITEMS
-- ============================================================

SELECT
    SUM(
        CASE
            WHEN PRICE IS NULL THEN 1
            ELSE 0
        END
    ) AS ERR_PRICE_NULL,

    SUM(
        CASE
            WHEN PRICE <= 0 THEN 1
            ELSE 0
        END
    ) AS ERR_PRICE,

    SUM(
        CASE
            WHEN FREIGHT_VALUE IS NULL THEN 1
            ELSE 0
        END
    ) AS ERR_FREIGHT_NULL,

    SUM(
        CASE
            WHEN FREIGHT_VALUE < 0 THEN 1
            ELSE 0
        END
    ) AS ERR_FREIGHT,

    SUM(
        CASE
            WHEN TOTAL_ITEM_VALUE IS NULL THEN 1
            ELSE 0
        END
    ) AS ERR_TOTAL_NULL,

    SUM(
        CASE
            WHEN ABS(
                TOTAL_ITEM_VALUE - (PRICE + FREIGHT_VALUE)
            ) > 0.01
            THEN 1
            ELSE 0
        END
    ) AS ERR_TOTAL_CALCUL

FROM GOLD.FACT_ORDER_ITEMS;


-- ============================================================
-- 21. STATISTIQUES ORDER_ITEMS
-- ============================================================

SELECT
    COUNT(*) AS NB_ITEMS,

    ROUND(SUM(PRICE), 2)
        AS TOTAL_PRICE,

    ROUND(SUM(FREIGHT_VALUE), 2)
        AS TOTAL_FREIGHT,

    ROUND(SUM(TOTAL_ITEM_VALUE), 2)
        AS TOTAL_ITEM_VALUE,

    ROUND(AVG(PRICE), 2)
        AS AVG_PRICE,

    ROUND(AVG(FREIGHT_VALUE), 2)
        AS AVG_FREIGHT,

    MIN(PRICE)
        AS MIN_PRICE,

    MAX(PRICE)
        AS MAX_PRICE

FROM GOLD.FACT_ORDER_ITEMS;


-- ============================================================
-- PARTIE C - FACT_PAYMENTS
-- ============================================================


-- 22. PAYMENT_VALUE NULL
-- Attendu : 0

SELECT
    COUNT(*) AS PAYMENT_VALUE_NULL
FROM GOLD.FACT_PAYMENTS
WHERE PAYMENT_VALUE IS NULL;


-- 23. PAYMENT_VALUE NEGATIF
-- Attendu : 0

SELECT
    COUNT(*) AS PAYMENT_VALUE_NEGATIF
FROM GOLD.FACT_PAYMENTS
WHERE PAYMENT_VALUE < 0;


-- 24. PAYMENT_VALUE = 0
-- Informatif

SELECT
    COUNT(*) AS PAYMENT_VALUE_ZERO
FROM GOLD.FACT_PAYMENTS
WHERE PAYMENT_VALUE = 0;


-- 25. INSTALLMENTS NULL
-- Attendu : 0

SELECT
    COUNT(*) AS INSTALLMENTS_NULL
FROM GOLD.FACT_PAYMENTS
WHERE PAYMENT_INSTALLMENTS IS NULL;


-- 26. INSTALLMENTS NEGATIFS
-- Attendu : 0

SELECT
    COUNT(*) AS INSTALLMENTS_NEGATIFS
FROM GOLD.FACT_PAYMENTS
WHERE PAYMENT_INSTALLMENTS < 0;


-- 27. INSTALLMENTS = 0
-- Informatif

SELECT
    COUNT(*) AS INSTALLMENTS_ZERO
FROM GOLD.FACT_PAYMENTS
WHERE PAYMENT_INSTALLMENTS = 0;


-- ============================================================
-- 28. REPARTITION PAR PAYMENT_TYPE
-- ============================================================

SELECT
    PAYMENT_TYPE,

    COUNT(*) AS NB_PAYMENTS,

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


-- ============================================================
-- 29. STATISTIQUES DES PAIEMENTS
-- ============================================================

SELECT
    COUNT(*) AS NB_PAYMENTS,

    COUNT(DISTINCT ORDER_ID)
        AS ORDERS_AVEC_PAYMENT,

    ROUND(SUM(PAYMENT_VALUE), 2)
        AS TOTAL_PAYMENT_VALUE,

    ROUND(AVG(PAYMENT_VALUE), 2)
        AS AVG_PAYMENT_VALUE,

    MIN(PAYMENT_VALUE)
        AS MIN_PAYMENT_VALUE,

    MAX(PAYMENT_VALUE)
        AS MAX_PAYMENT_VALUE,

    ROUND(AVG(PAYMENT_INSTALLMENTS), 2)
        AS AVG_INSTALLMENTS,

    MIN(PAYMENT_INSTALLMENTS)
        AS MIN_INSTALLMENTS,

    MAX(PAYMENT_INSTALLMENTS)
        AS MAX_INSTALLMENTS

FROM GOLD.FACT_PAYMENTS;


-- ============================================================
-- 30. SYNTHESE PAYMENTS
--
-- Attendu :
-- ERROR_COUNT = 0
-- ============================================================

SELECT
    SUM(
        CASE
            WHEN PAYMENT_VALUE IS NULL
              OR PAYMENT_VALUE < 0
            THEN 1
            ELSE 0
        END
    )
    +
    SUM(
        CASE
            WHEN PAYMENT_INSTALLMENTS IS NULL
              OR PAYMENT_INSTALLMENTS < 0
            THEN 1
            ELSE 0
        END
    ) AS ERROR_COUNT

FROM GOLD.FACT_PAYMENTS;


-- ============================================================
-- PARTIE D - FACT_REVIEWS
-- ============================================================


-- 31. REVIEW_SCORE NULL
-- Attendu : 0

SELECT
    COUNT(*) AS REVIEW_SCORE_NULL
FROM GOLD.FACT_REVIEWS
WHERE REVIEW_SCORE IS NULL;


-- 32. REVIEW_SCORE INVALIDE
-- Attendu : 0

SELECT
    COUNT(*) AS REVIEW_SCORE_INVALIDE
FROM GOLD.FACT_REVIEWS
WHERE REVIEW_SCORE < 1
   OR REVIEW_SCORE > 5;


-- ============================================================
-- 33. REPARTITION DES SCORES
--
-- VERSION CORRIGEE POUR ORACLE
-- ============================================================

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
-- 34. STATISTIQUES DES REVIEWS
-- ============================================================

SELECT
    COUNT(*) AS NB_REVIEWS,

    COUNT(DISTINCT ORDER_ID)
        AS ORDERS_AVEC_REVIEW,

    ROUND(AVG(REVIEW_SCORE), 2)
        AS AVG_REVIEW_SCORE,

    MIN(REVIEW_SCORE)
        AS MIN_REVIEW_SCORE,

    MAX(REVIEW_SCORE)
        AS MAX_REVIEW_SCORE

FROM GOLD.FACT_REVIEWS;


-- ============================================================
-- 35. SYNTHESE REVIEWS
--
-- Attendu :
-- ERROR_COUNT = 0
-- ============================================================

SELECT
    COUNT(*) AS ERROR_COUNT
FROM GOLD.FACT_REVIEWS
WHERE REVIEW_SCORE IS NULL
   OR REVIEW_SCORE < 1
   OR REVIEW_SCORE > 5;


-- ============================================================
-- PARTIE E - CONTROLES CROISES
-- ============================================================


-- ============================================================
-- 36. ARTICLES PAR COMMANDE
-- ============================================================

SELECT
    MIN(NB_ITEMS)
        AS MIN_ITEMS_PAR_ORDER,

    ROUND(AVG(NB_ITEMS), 2)
        AS AVG_ITEMS_PAR_ORDER,

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
-- 37. PAIEMENTS PAR COMMANDE
-- ============================================================

SELECT
    MIN(NB_PAYMENTS)
        AS MIN_PAYMENTS_PAR_ORDER,

    ROUND(AVG(NB_PAYMENTS), 2)
        AS AVG_PAYMENTS_PAR_ORDER,

    MAX(NB_PAYMENTS)
        AS MAX_PAYMENTS_PAR_ORDER

FROM (
    SELECT
        ORDER_ID,
        COUNT(*) AS NB_PAYMENTS
    FROM GOLD.FACT_PAYMENTS
    GROUP BY ORDER_ID
);


-- ============================================================
-- 38. REVIEWS PAR COMMANDE
-- ============================================================

SELECT
    MIN(NB_REVIEWS)
        AS MIN_REVIEWS_PAR_ORDER,

    ROUND(AVG(NB_REVIEWS), 2)
        AS AVG_REVIEWS_PAR_ORDER,

    MAX(NB_REVIEWS)
        AS MAX_REVIEWS_PAR_ORDER

FROM (
    SELECT
        ORDER_ID,
        COUNT(*) AS NB_REVIEWS
    FROM GOLD.FACT_REVIEWS
    GROUP BY ORDER_ID
);


-- ============================================================
-- 39. COMPARAISON TOTAL ITEMS / TOTAL PAIEMENTS
--
-- IMPORTANT :
-- Chaque table est d'abord agregee par ORDER_ID.
--
-- Cela evite la multiplication des lignes quand une commande
-- contient plusieurs articles et plusieurs paiements.
-- ============================================================

SELECT
    COUNT(*) AS ORDERS_COMPAREES,

    ROUND(
        SUM(I.ITEM_TOTAL),
        2
    ) AS TOTAL_ITEMS,

    ROUND(
        SUM(P.PAYMENT_TOTAL),
        2
    ) AS TOTAL_PAYMENTS,

    ROUND(
        SUM(P.PAYMENT_TOTAL)
        -
        SUM(I.ITEM_TOTAL),
        2
    ) AS DIFFERENCE

FROM (
    SELECT
        ORDER_ID,
        SUM(TOTAL_ITEM_VALUE) AS ITEM_TOTAL

    FROM GOLD.FACT_ORDER_ITEMS

    GROUP BY ORDER_ID
) I

INNER JOIN (
    SELECT
        ORDER_ID,
        SUM(PAYMENT_VALUE) AS PAYMENT_TOTAL

    FROM GOLD.FACT_PAYMENTS

    GROUP BY ORDER_ID
) P

    ON P.ORDER_ID = I.ORDER_ID;


-- ============================================================
-- 40. COMMANDES AVEC DIFFERENCE ITEMS / PAIEMENTS
--
-- Une difference n'est pas automatiquement une erreur.
--
-- Seuil :
-- ABS(PAYMENT_TOTAL - ITEM_TOTAL) > 0.01
-- ============================================================

SELECT
    COUNT(*) AS ORDERS_AVEC_DIFFERENCE

FROM (
    SELECT
        I.ORDER_ID,
        I.ITEM_TOTAL,
        P.PAYMENT_TOTAL

    FROM (
        SELECT
            ORDER_ID,
            SUM(TOTAL_ITEM_VALUE) AS ITEM_TOTAL

        FROM GOLD.FACT_ORDER_ITEMS

        GROUP BY ORDER_ID
    ) I

    INNER JOIN (
        SELECT
            ORDER_ID,
            SUM(PAYMENT_VALUE) AS PAYMENT_TOTAL

        FROM GOLD.FACT_PAYMENTS

        GROUP BY ORDER_ID
    ) P

        ON P.ORDER_ID = I.ORDER_ID

    WHERE ABS(
        P.PAYMENT_TOTAL - I.ITEM_TOTAL
    ) > 0.01
);


-- ============================================================
-- 41. TOP 20 DIFFERENCES ITEMS / PAIEMENTS
--
-- Controle analytique.
-- ============================================================

SELECT *
FROM (
    SELECT
        I.ORDER_ID,

        ROUND(
            I.ITEM_TOTAL,
            2
        ) AS ITEM_TOTAL,

        ROUND(
            P.PAYMENT_TOTAL,
            2
        ) AS PAYMENT_TOTAL,

        ROUND(
            P.PAYMENT_TOTAL - I.ITEM_TOTAL,
            2
        ) AS DIFFERENCE

    FROM (
        SELECT
            ORDER_ID,
            SUM(TOTAL_ITEM_VALUE) AS ITEM_TOTAL

        FROM GOLD.FACT_ORDER_ITEMS

        GROUP BY ORDER_ID
    ) I

    INNER JOIN (
        SELECT
            ORDER_ID,
            SUM(PAYMENT_VALUE) AS PAYMENT_TOTAL

        FROM GOLD.FACT_PAYMENTS

        GROUP BY ORDER_ID
    ) P

        ON P.ORDER_ID = I.ORDER_ID

    WHERE ABS(
        P.PAYMENT_TOTAL - I.ITEM_TOTAL
    ) > 0.01

    ORDER BY
        ABS(
            P.PAYMENT_TOTAL - I.ITEM_TOTAL
        ) DESC
)
WHERE ROWNUM <= 20;


-- ============================================================
-- PARTIE F - AUDIT FINAL DES MESURES
-- ============================================================


-- ============================================================
-- 42. SYNTHESE FINALE
--
-- Attendu :
-- ERROR_COUNT = 0 pour toutes les lignes.
-- ============================================================

SELECT
    'DELIVERY_DAYS_NEGATIVE' AS CONTROL_NAME,
    COUNT(*) AS ERROR_COUNT

FROM GOLD.FACT_ORDERS

WHERE DELIVERY_DAYS < 0


UNION ALL


SELECT
    'DELIVERY_DAYS_CALCULATION',
    COUNT(*)

FROM GOLD.FACT_ORDERS

WHERE ORDER_DELIVERED_CUSTOMER_DATE IS NOT NULL
  AND DELIVERY_DAYS <>
      (
          TRUNC(
              CAST(
                  ORDER_DELIVERED_CUSTOMER_DATE AS DATE
              )
          )
          -
          TRUNC(
              CAST(
                  ORDER_PURCHASE_TIMESTAMP AS DATE
              )
          )
      )


UNION ALL


SELECT
    'DELIVERY_DELAY_CALCULATION',
    COUNT(*)

FROM GOLD.FACT_ORDERS

WHERE ORDER_DELIVERED_CUSTOMER_DATE IS NOT NULL
  AND ORDER_ESTIMATED_DELIVERY_DATE IS NOT NULL
  AND DELIVERY_DELAY_DAYS <>
      (
          TRUNC(
              CAST(
                  ORDER_DELIVERED_CUSTOMER_DATE AS DATE
              )
          )
          -
          TRUNC(
              CAST(
                  ORDER_ESTIMATED_DELIVERY_DATE AS DATE
              )
          )
      )


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
    'ORDER_ITEM_PRICE',
    COUNT(*)

FROM GOLD.FACT_ORDER_ITEMS

WHERE PRICE IS NULL
   OR PRICE <= 0


UNION ALL


SELECT
    'ORDER_ITEM_FREIGHT',
    COUNT(*)

FROM GOLD.FACT_ORDER_ITEMS

WHERE FREIGHT_VALUE IS NULL
   OR FREIGHT_VALUE < 0


UNION ALL


SELECT
    'ORDER_ITEM_TOTAL',
    COUNT(*)

FROM GOLD.FACT_ORDER_ITEMS

WHERE TOTAL_ITEM_VALUE IS NULL
   OR ABS(
          TOTAL_ITEM_VALUE
          -
          (PRICE + FREIGHT_VALUE)
      ) > 0.01


UNION ALL


SELECT
    'PAYMENT_VALUE',
    COUNT(*)

FROM GOLD.FACT_PAYMENTS

WHERE PAYMENT_VALUE IS NULL
   OR PAYMENT_VALUE < 0


UNION ALL


SELECT
    'PAYMENT_INSTALLMENTS',
    COUNT(*)

FROM GOLD.FACT_PAYMENTS

WHERE PAYMENT_INSTALLMENTS IS NULL
   OR PAYMENT_INSTALLMENTS < 0


UNION ALL


SELECT
    'REVIEW_SCORE',
    COUNT(*)

FROM GOLD.FACT_REVIEWS

WHERE REVIEW_SCORE IS NULL
   OR REVIEW_SCORE < 1
   OR REVIEW_SCORE > 5

ORDER BY CONTROL_NAME;


-- ============================================================
-- FIN
-- 12_validate_gold_measures.sql
-- ============================================================