-- ============================================================
-- MODERN DATA PLATFORM - OLIST
-- GOLD
-- 10_load_fact_reviews.sql
--
-- CHARGEMENT DE GOLD.FACT_REVIEWS
--
-- Grain :
-- 1 ligne = (REVIEW_ID, ORDER_ID)
--
-- Source :
-- SILVER.REVIEWS
--
-- Volume attendu :
-- 99 193 lignes
--
-- Structure GOLD :
--
-- REVIEW_ID
-- ORDER_ID
-- CUSTOMER_KEY
-- REVIEW_DATE_KEY
-- REVIEW_SCORE
--
-- REVIEW_DATE_KEY est determinee a partir de :
-- SILVER.REVIEWS.REVIEW_CREATION_DATE
-- ============================================================


-- ============================================================
-- 0. NETTOYAGE
-- ============================================================

DELETE FROM GOLD.FACT_REVIEWS;

COMMIT;


-- ============================================================
-- 1. CHARGEMENT DE FACT_REVIEWS
--
-- CUSTOMER_KEY :
-- recuperee depuis FACT_ORDERS.
--
-- REVIEW_DATE_KEY :
-- recherchee dans DIM_DATE a partir de
-- REVIEW_CREATION_DATE.
--
-- REVIEW_CREATION_DATE et REVIEW_ANSWER_TIMESTAMP
-- restent dans SILVER et ne sont pas stockes dans
-- FACT_REVIEWS.
-- ============================================================

INSERT INTO GOLD.FACT_REVIEWS (
    REVIEW_ID,
    ORDER_ID,
    CUSTOMER_KEY,
    REVIEW_DATE_KEY,
    REVIEW_SCORE
)
SELECT
    R.REVIEW_ID,

    R.ORDER_ID,

    O.CUSTOMER_KEY,

    D.DATE_KEY,

    R.REVIEW_SCORE

FROM SILVER.REVIEWS R

INNER JOIN GOLD.FACT_ORDERS O
    ON O.ORDER_ID = R.ORDER_ID

INNER JOIN GOLD.DIM_DATE D
    ON D.FULL_DATE =
       TRUNC(
           CAST(
               R.REVIEW_CREATION_DATE AS DATE
           )
       );


COMMIT;


-- ============================================================
-- 2. VOLUME TOTAL
--
-- Attendu :
-- 99 193
-- ============================================================

SELECT
    COUNT(*) AS NB_REVIEWS
FROM GOLD.FACT_REVIEWS;


-- ============================================================
-- 3. RECONCILIATION SILVER / GOLD
--
-- Attendu :
--
-- SILVER_REVIEWS = 99 193
-- GOLD_REVIEWS   = 99 193
-- ECART          = 0
-- ============================================================

SELECT
    (
        SELECT COUNT(*)
        FROM SILVER.REVIEWS
    ) AS SILVER_REVIEWS,

    (
        SELECT COUNT(*)
        FROM GOLD.FACT_REVIEWS
    ) AS GOLD_REVIEWS,

    (
        SELECT COUNT(*)
        FROM SILVER.REVIEWS
    )
    -
    (
        SELECT COUNT(*)
        FROM GOLD.FACT_REVIEWS
    ) AS ECART

FROM DUAL;


-- ============================================================
-- 4. CONTROLE DU GRAIN
--
-- Grain :
-- (REVIEW_ID, ORDER_ID)
--
-- Attendu :
-- 0 doublon
-- ============================================================

SELECT
    COUNT(*) AS GRAIN_DUPLIQUE
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
-- 5. REVIEW_ID NULL
--
-- Attendu :
-- 0
-- ============================================================

SELECT
    COUNT(*) AS REVIEW_ID_NULL
FROM GOLD.FACT_REVIEWS
WHERE REVIEW_ID IS NULL;


-- ============================================================
-- 6. ORDER_ID NULL
--
-- Attendu :
-- 0
-- ============================================================

SELECT
    COUNT(*) AS ORDER_ID_NULL
FROM GOLD.FACT_REVIEWS
WHERE ORDER_ID IS NULL;


-- ============================================================
-- 7. CUSTOMER_KEY NULL
--
-- Attendu :
-- 0
-- ============================================================

SELECT
    COUNT(*) AS CUSTOMER_KEY_NULL
FROM GOLD.FACT_REVIEWS
WHERE CUSTOMER_KEY IS NULL;


-- ============================================================
-- 8. REVIEW_DATE_KEY NULL
--
-- Attendu :
-- 0
-- ============================================================

SELECT
    COUNT(*) AS REVIEW_DATE_KEY_NULL
FROM GOLD.FACT_REVIEWS
WHERE REVIEW_DATE_KEY IS NULL;


-- ============================================================
-- 9. REVIEW_SCORE NULL
--
-- Attendu :
-- 0
-- ============================================================

SELECT
    COUNT(*) AS REVIEW_SCORE_NULL
FROM GOLD.FACT_REVIEWS
WHERE REVIEW_SCORE IS NULL;


-- ============================================================
-- 10. CONTROLE FK FACT_ORDERS
--
-- Chaque avis doit correspondre a une commande.
--
-- Attendu :
-- 0
-- ============================================================

SELECT
    COUNT(*) AS REVIEWS_SANS_FACT_ORDER
FROM GOLD.FACT_REVIEWS R

WHERE NOT EXISTS (
    SELECT 1
    FROM GOLD.FACT_ORDERS O
    WHERE O.ORDER_ID = R.ORDER_ID
);


-- ============================================================
-- 11. CONTROLE FK DIM_CUSTOMER
--
-- Attendu :
-- 0
-- ============================================================

SELECT
    COUNT(*) AS REVIEWS_SANS_DIM_CUSTOMER
FROM GOLD.FACT_REVIEWS R

WHERE NOT EXISTS (
    SELECT 1
    FROM GOLD.DIM_CUSTOMER C
    WHERE C.CUSTOMER_KEY = R.CUSTOMER_KEY
);


-- ============================================================
-- 12. CONTROLE FK DIM_DATE
--
-- Attendu :
-- 0
-- ============================================================

SELECT
    COUNT(*) AS REVIEWS_SANS_DIM_DATE
FROM GOLD.FACT_REVIEWS R

WHERE NOT EXISTS (
    SELECT 1
    FROM GOLD.DIM_DATE D
    WHERE D.DATE_KEY = R.REVIEW_DATE_KEY
);


-- ============================================================
-- 13. AVIS SILVER ABSENTS DE GOLD
--
-- Verification avec le grain complet.
--
-- Attendu :
-- 0
-- ============================================================

SELECT
    COUNT(*) AS SILVER_REVIEWS_ABSENTS_GOLD
FROM SILVER.REVIEWS S

WHERE NOT EXISTS (
    SELECT 1
    FROM GOLD.FACT_REVIEWS G
    WHERE G.REVIEW_ID = S.REVIEW_ID
      AND G.ORDER_ID = S.ORDER_ID
);


-- ============================================================
-- 14. AVIS GOLD ABSENTS DE SILVER
--
-- Attendu :
-- 0
-- ============================================================

SELECT
    COUNT(*) AS GOLD_REVIEWS_ABSENTS_SILVER
FROM GOLD.FACT_REVIEWS G

WHERE NOT EXISTS (
    SELECT 1
    FROM SILVER.REVIEWS S
    WHERE S.REVIEW_ID = G.REVIEW_ID
      AND S.ORDER_ID = G.ORDER_ID
);


-- ============================================================
-- 15. REVIEW_SCORE INVALIDE
--
-- Regle metier :
--
-- 1 <= REVIEW_SCORE <= 5
--
-- Attendu :
-- 0
-- ============================================================

SELECT
    COUNT(*) AS REVIEW_SCORE_INVALIDE
FROM GOLD.FACT_REVIEWS

WHERE REVIEW_SCORE < 1
   OR REVIEW_SCORE > 5;


-- ============================================================
-- 16. COHERENCE CUSTOMER_KEY AVEC FACT_ORDERS
--
-- L'avis doit avoir le meme CUSTOMER_KEY
-- que la commande correspondante.
--
-- Attendu :
-- 0
-- ============================================================

SELECT
    COUNT(*) AS CUSTOMER_KEY_INCOHERENT
FROM GOLD.FACT_REVIEWS R

INNER JOIN GOLD.FACT_ORDERS O
    ON O.ORDER_ID = R.ORDER_ID

WHERE R.CUSTOMER_KEY <> O.CUSTOMER_KEY;


-- ============================================================
-- 17. COHERENCE REVIEW_DATE_KEY
--
-- On reconstruit la date a partir de SILVER
-- et on la compare a DIM_DATE.
--
-- Attendu 