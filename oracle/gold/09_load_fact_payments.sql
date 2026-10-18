-- ============================================================
-- MODERN DATA PLATFORM - OLIST
-- GOLD
-- 09_load_fact_payments.sql
--
-- CHARGEMENT DE GOLD.FACT_PAYMENTS
--
-- Grain :
-- 1 ligne = (ORDER_ID, PAYMENT_SEQUENTIAL)
--
-- Source :
-- SILVER.PAYMENTS
--
-- Volume attendu :
-- 103 852 lignes
--
-- Dimensions :
-- DIM_CUSTOMER
-- DIM_DATE
--
-- Relation :
-- FACT_ORDERS
--
-- Mesures :
-- PAYMENT_INSTALLMENTS
-- PAYMENT_VALUE
-- ============================================================


-- ============================================================
-- 0. NETTOYAGE
--
-- Permet de relancer le script.
-- ============================================================

DELETE FROM GOLD.FACT_PAYMENTS;

COMMIT;


-- ============================================================
-- 1. CHARGEMENT DE FACT_PAYMENTS
--
-- CUSTOMER_KEY et PURCHASE_DATE_KEY sont recuperes
-- directement depuis FACT_ORDERS.
--
-- Cela garantit que le paiement utilise exactement
-- le meme client et la meme date d'achat que la commande.
-- ============================================================

INSERT INTO GOLD.FACT_PAYMENTS (
    ORDER_ID,
    PAYMENT_SEQUENTIAL,
    CUSTOMER_KEY,
    PURCHASE_DATE_KEY,
    PAYMENT_TYPE,
    PAYMENT_INSTALLMENTS,
    PAYMENT_VALUE
)
SELECT
    P.ORDER_ID,

    P.PAYMENT_SEQUENTIAL,

    O.CUSTOMER_KEY,

    O.PURCHASE_DATE_KEY,

    P.PAYMENT_TYPE,

    P.PAYMENT_INSTALLMENTS,

    P.PAYMENT_VALUE

FROM SILVER.PAYMENTS P

INNER JOIN GOLD.FACT_ORDERS O
    ON O.ORDER_ID = P.ORDER_ID;


COMMIT;


-- ============================================================
-- 2. VOLUME TOTAL
--
-- Attendu :
-- 103 852
-- ============================================================

SELECT
    COUNT(*) AS NB_PAYMENTS
FROM GOLD.FACT_PAYMENTS;


-- ============================================================
-- 3. RECONCILIATION SILVER / GOLD
--
-- Attendu :
--
-- SILVER_PAYMENTS = 103 852
-- GOLD_PAYMENTS   = 103 852
-- ECART           = 0
-- ============================================================

SELECT
    (
        SELECT COUNT(*)
        FROM SILVER.PAYMENTS
    ) AS SILVER_PAYMENTS,

    (
        SELECT COUNT(*)
        FROM GOLD.FACT_PAYMENTS
    ) AS GOLD_PAYMENTS,

    (
        SELECT COUNT(*)
        FROM SILVER.PAYMENTS
    )
    -
    (
        SELECT COUNT(*)
        FROM GOLD.FACT_PAYMENTS
    ) AS ECART

FROM DUAL;


-- ============================================================
-- 4. CONTROLE DU GRAIN
--
-- Grain :
-- (ORDER_ID, PAYMENT_SEQUENTIAL)
--
-- Attendu :
-- 0
-- ============================================================

SELECT
    COUNT(*) AS GRAIN_DUPLIQUE
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
-- 5. ORDER_ID NULL
--
-- Attendu :
-- 0
-- ============================================================

SELECT
    COUNT(*) AS ORDER_ID_NULL
FROM GOLD.FACT_PAYMENTS
WHERE ORDER_ID IS NULL;


-- ============================================================
-- 6. PAYMENT_SEQUENTIAL NULL
--
-- Attendu :
-- 0
-- ============================================================

SELECT
    COUNT(*) AS PAYMENT_SEQUENTIAL_NULL
FROM GOLD.FACT_PAYMENTS
WHERE PAYMENT_SEQUENTIAL IS NULL;


-- ============================================================
-- 7. CUSTOMER_KEY NULL
--
-- Attendu :
-- 0
-- ============================================================

SELECT
    COUNT(*) AS CUSTOMER_KEY_NULL
FROM GOLD.FACT_PAYMENTS
WHERE CUSTOMER_KEY IS NULL;


-- ============================================================
-- 8. PURCHASE_DATE_KEY NULL
--
-- Attendu :
-- 0
-- ============================================================

SELECT
    COUNT(*) AS PURCHASE_DATE_KEY_NULL
FROM GOLD.FACT_PAYMENTS
WHERE PURCHASE_DATE_KEY IS NULL;


-- ============================================================
-- 9. CONTROLE FK FACT_ORDERS
--
-- Chaque paiement doit correspondre
-- a une commande GOLD.
--
-- Attendu :
-- 0
-- ============================================================

SELECT
    COUNT(*) AS PAYMENTS_SANS_FACT_ORDER
FROM GOLD.FACT_PAYMENTS P
WHERE NOT EXISTS (
    SELECT 1
    FROM GOLD.FACT_ORDERS O
    WHERE O.ORDER_ID = P.ORDER_ID
);


-- ============================================================
-- 10. CONTROLE FK DIM_CUSTOMER
--
-- Attendu :
-- 0
-- ============================================================

SELECT
    COUNT(*) AS PAYMENTS_SANS_DIM_CUSTOMER
FROM GOLD.FACT_PAYMENTS P
WHERE NOT EXISTS (
    SELECT 1
    FROM GOLD.DIM_CUSTOMER C
    WHERE C.CUSTOMER_KEY = P.CUSTOMER_KEY
);


-- ============================================================
-- 11. CONTROLE FK DIM_DATE
--
-- Attendu :
-- 0
-- ============================================================

SELECT
    COUNT(*) AS PAYMENTS_SANS_DIM_DATE
FROM GOLD.FACT_PAYMENTS P
WHERE NOT EXISTS (
    SELECT 1
    FROM GOLD.DIM_DATE D
    WHERE D.DATE_KEY = P.PURCHASE_DATE_KEY
);


-- ============================================================
-- 12. PAIEMENTS SILVER ABSENTS DE GOLD
--
-- Controle ligne par ligne.
--
-- Attendu :
-- 0
-- ============================================================

SELECT
    COUNT(*) AS SILVER_PAYMENTS_ABSENTS_GOLD
FROM SILVER.PAYMENTS S
WHERE NOT EXISTS (
    SELECT 1
    FROM GOLD.FACT_PAYMENTS G
    WHERE G.ORDER_ID = S.ORDER_ID
      AND G.PAYMENT_SEQUENTIAL = S.PAYMENT_SEQUENTIAL
);


-- ============================================================
-- 13. PAIEMENTS GOLD ABSENTS DE SILVER
--
-- Attendu :
-- 0
-- ============================================================

SELECT
    COUNT(*) AS GOLD_PAYMENTS_ABSENTS_SILVER
FROM GOLD.FACT_PAYMENTS G
WHERE NOT EXISTS (
    SELECT 1
    FROM SILVER.PAYMENTS S
    WHERE S.ORDER_ID = G.ORDER_ID
      AND S.PAYMENT_SEQUENTIAL = G.PAYMENT_SEQUENTIAL
);


-- ============================================================
-- 14. PAYMENT_TYPE NULL
--
-- Controle informatif.
-- ============================================================

SELECT
    COUNT(*) AS PAYMENT_TYPE_NULL
FROM GOLD.FACT_PAYMENTS
WHERE PAYMENT_TYPE IS NULL;


-- ============================================================
-- 15. REPARTITION PAR TYPE DE PAIEMENT
-- ============================================================

SELECT
    PAYMENT_TYPE,
    COUNT(*) AS NB_PAYMENTS,
    ROUND(
        SUM(PAYMENT_VALUE),
        2
    ) AS TOTAL_PAYMENT_VALUE

FROM GOLD.FACT_PAYMENTS

GROUP BY PAYMENT_TYPE

ORDER BY NB_PAYMENTS DESC;


-- ============================================================
-- 16. PAYMENT_VALUE NULL
--
-- Attendu :
-- 0
-- ============================================================

SELECT
    COUNT(*) AS PAYMENT_VALUE_NULL
FROM GOLD.FACT_PAYMENTS
WHERE PAYMENT_VALUE IS NULL;


-- ============================================================
-- 17. PAYMENT_VALUE NEGATIF
--
-- La structure GOLD autorise 0 mais pas une
-- valeur negative.
--
-- Attendu :
-- 0
-- ============================================================

SELECT
    COUNT(*) AS PAYMENT_VALUE_NEGATIF
FROM GOLD.FACT_PAYMENTS
WHERE PAYMENT_VALUE < 0;


-- ============================================================
-- 18. PAYMENT_VALUE = 0
--
-- Controle informatif.
--
-- On ne considere pas automatiquement une valeur 0 comme
-- une erreur puisque la contrainte GOLD autorise >= 0.
-- ============================================================

SELECT
    COUNT(*) AS PAYMENT_VALUE_ZERO
FROM GOLD.FACT_PAYMENTS
WHERE PAYMENT_VALUE = 0;


-- ============================================================
-- 19. PAYMENT_INSTALLMENTS NULL
--
-- Controle informatif.
-- ============================================================

SELECT
    COUNT(*) AS PAYMENT_INSTALLMENTS_NULL
FROM GOLD.FACT_PAYMENTS
WHERE PAYMENT_INSTALLMENTS IS NULL;


-- ============================================================
-- 20. PAYMENT_INSTALLMENTS NEGATIF
--
-- Attendu :
-- 0
-- ============================================================

SELECT
    COUNT(*) AS INSTALLMENTS_NEGATIFS
FROM GOLD.FACT_PAYMENTS
WHERE PAYMENT_INSTALLMENTS < 0;


-- ============================================================
-- 21. PAYMENT_INSTALLMENTS = 0
--
-- Controle informatif.
--
-- La contrainte GOLD actuelle autorise >= 0.
-- On mesure donc les valeurs 0 sans les supprimer.
-- ============================================================

SELECT
    COUNT(*) AS INSTALLMENTS_ZERO
FROM GOLD.FACT_PAYMENTS
WHERE PAYMENT_INSTALLMENTS = 0;


-- ============================================================
-- 22. COHERENCE CUSTOMER_KEY AVEC FACT_ORDERS
--
-- Le paiement doit avoir le meme CUSTOMER_KEY
-- que sa commande.
--
-- Attendu :
-- 0
-- ============================================================

SELECT
    COUNT(*) AS CUSTOMER_KEY_INCOHERENT
FROM GOLD.FACT_PAYMENTS P

INNER JOIN GOLD.FACT_ORDERS O
    ON O.ORDER_ID = P.ORDER_ID

WHERE P.CUSTOMER_KEY <> O.CUSTOMER_KEY;


-- ============================================================
-- 23. COHERENCE PURCHASE_DATE_KEY AVEC FACT_ORDERS
--
-- Le paiement doit utiliser la meme date d'achat
-- que la commande.
--
-- Attendu :
-- 0
-- ============================================================

SELECT
    COUNT(*) AS PURCHASE_DATE_KEY_INCOHERENT
FROM GOLD.FACT_PAYMENTS P

INNER JOIN GOLD.FACT_ORDERS O
    ON O.ORDER_ID = P.ORDER_ID

WHERE P.PURCHASE_DATE_KEY <> O.PURCHASE_DATE_KEY;


-- ============================================================
-- 24. COHERENCE DES VALEURS AVEC SILVER
--
-- PAYMENT_VALUE doit rester identique entre
-- SILVER et GOLD.
--
-- Attendu :
-- 0
-- ============================================================

SELECT
    COUNT(*) AS PAYMENT_VALUE_INCOHERENT
FROM GOLD.FACT_PAYMENTS G

INNER JOIN SILVER.PAYMENTS S
    ON S.ORDER_ID = G.ORDER_ID
   AND S.PAYMENT_SEQUENTIAL = G.PAYMENT_SEQUENTIAL

WHERE ABS(
    G.PAYMENT_VALUE - S.PAYMENT_VALUE
) > 0.01;


-- ============================================================
-- 25. COHERENCE PAYMENT_TYPE AVEC SILVER
--
-- Attendu :
-- 0
-- ============================================================

SELECT
    COUNT(*) AS PAYMENT_TYPE_INCOHERENT
FROM GOLD.FACT_PAYMENTS G

INNER JOIN SILVER.PAYMENTS S
    ON S.ORDER_ID = G.ORDER_ID
   AND S.PAYMENT_SEQUENTIAL = G.PAYMENT_SEQUENTIAL

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
-- 26. COHERENCE INSTALLMENTS AVEC SILVER
--
-- Attendu :
-- 0
-- ============================================================

SELECT
    COUNT(*) AS INSTALLMENTS_INCOHERENTS
FROM GOLD.FACT_PAYMENTS G

INNER JOIN SILVER.PAYMENTS S
    ON S.ORDER_ID = G.ORDER_ID
   AND S.PAYMENT_SEQUENTIAL = G.PAYMENT_SEQUENTIAL

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
-- 27. STATISTIQUES SUR LES PAIEMENTS
-- ============================================================

SELECT
    COUNT(*) AS NB_PAYMENTS,

    COUNT(DISTINCT ORDER_ID)
        AS ORDERS_AVEC_PAYMENT,

    ROUND(
        SUM(PAYMENT_VALUE),
        2
    ) AS TOTAL_PAYMENT_VALUE,

    ROUND(
        AVG(PAYMENT_VALUE),
        2
    ) AS PAYMENT_VALUE_MOYEN,

    MIN(PAYMENT_VALUE)
        AS PAYMENT_VALUE_MIN,

    MAX(PAYMENT_VALUE)
        AS PAYMENT_VALUE_MAX

FROM GOLD.FACT_PAYMENTS;


-- ============================================================
-- 28. STATISTIQUES SUR LES MENSUALITES
-- ============================================================

SELECT
    ROUND(
        AVG(PAYMENT_INSTALLMENTS),
        2
    ) AS INSTALLMENTS_MOYEN,

    MIN(PAYMENT_INSTALLMENTS)
        AS INSTALLMENTS_MIN,

    MAX(PAYMENT_INSTALLMENTS)
        AS INSTALLMENTS_MAX

FROM GOLD.FACT_PAYMENTS;


-- ============================================================
-- 29. NOMBRE DE PAIEMENTS PAR COMMANDE
-- ============================================================

SELECT
    MIN(NB_PAYMENTS)
        AS MIN_PAYMENTS_PAR_ORDER,

    ROUND(
        AVG(NB_PAYMENTS),
        2
    ) AS AVG_PAYMENTS_PAR_ORDER,

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
-- 30. COMMANDES AVEC PLUSIEURS PAIEMENTS
-- ============================================================

SELECT
    COUNT(*) AS ORDERS_MULTI_PAYMENTS

FROM (
    SELECT
        ORDER_ID

    FROM GOLD.FACT_PAYMENTS

    GROUP BY ORDER_ID

    HAVING COUNT(*) > 1
);


-- ============================================================
-- 31. APERCU
-- ============================================================

SELECT *
FROM (
    SELECT
        ORDER_ID,
        PAYMENT_SEQUENTIAL,
        CUSTOMER_KEY,
        PURCHASE_DATE_KEY,
        PAYMENT_TYPE,
        PAYMENT_INSTALLMENTS,
        PAYMENT_VALUE

    FROM GOLD.FACT_PAYMENTS

    ORDER BY
        ORDER_ID,
        PAYMENT_SEQUENTIAL
)
WHERE ROWNUM <= 20;


-- ============================================================
-- 32. SYNTHESE FINALE
--
-- Les compteurs d'invalidite structurelle doivent
-- etre a 0.
-- ============================================================

SELECT
    COUNT(*) AS TOTAL_PAYMENTS,

    COUNT(
        DISTINCT
        ORDER_ID || ':' || TO_CHAR(PAYMENT_SEQUENTIAL)
    ) AS GRAINS_DISTINCTS,

    SUM(
        CASE
            WHEN PAYMENT_VALUE < 0
            THEN 1
            ELSE 0
        END
    ) AS PAYMENT_VALUE_NEGATIFS,

    SUM(
        CASE
            WHEN PAYMENT_INSTALLMENTS < 0
            THEN 1
            ELSE 0
        END
    ) AS INSTALLMENTS_NEGATIFS

FROM GOLD.FACT_PAYMENTS;