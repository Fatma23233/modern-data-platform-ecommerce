-- ============================================================
-- MODERN DATA PLATFORM - OLIST
-- ETAPE 4.6
-- ANALYSE DES DOUBLONS DE REVIEWS
--
-- Aucune donnée n'est modifiée.
-- ============================================================


-- ============================================================
-- 1. VOLUME TOTAL
-- ============================================================

SELECT
    COUNT(*) AS TOTAL_REVIEWS
FROM BRONZE.REVIEWS_RAW;


-- ============================================================
-- 2. NOMBRE DE REVIEW_ID UNIQUES
-- ============================================================

SELECT
    COUNT(DISTINCT REVIEW_ID)
        AS REVIEW_ID_UNIQUES
FROM BRONZE.REVIEWS_RAW;


-- ============================================================
-- 3. REVIEW_ID PRESENTS PLUSIEURS FOIS
-- ============================================================

SELECT
    COUNT(*) AS REVIEW_ID_DUPLIQUES
FROM (
    SELECT REVIEW_ID
    FROM BRONZE.REVIEWS_RAW
    GROUP BY REVIEW_ID
    HAVING COUNT(*) > 1
);


-- ============================================================
-- 4. NOMBRE DE LIGNES APPARTENANT A CES DOUBLONS
-- ============================================================

SELECT
    SUM(NB) AS LIGNES_DANS_DOUBLONS
FROM (
    SELECT
        REVIEW_ID,
        COUNT(*) AS NB
    FROM BRONZE.REVIEWS_RAW
    GROUP BY REVIEW_ID
    HAVING COUNT(*) > 1
);


-- ============================================================
-- 5. REPARTITION DU NOMBRE D'OCCURRENCES
--
-- Exemple :
-- 2 occurrences -> X review_id
-- 3 occurrences -> Y review_id
-- ============================================================

SELECT
    NB_OCCURRENCES,
    COUNT(*) AS NB_REVIEW_ID
FROM (
    SELECT
        REVIEW_ID,
        COUNT(*) AS NB_OCCURRENCES
    FROM BRONZE.REVIEWS_RAW
    GROUP BY REVIEW_ID
    HAVING COUNT(*) > 1
)
GROUP BY NB_OCCURRENCES
ORDER BY NB_OCCURRENCES;

-- ============================================================
-- 6. DOUBLONS COMPLETEMENT IDENTIQUES
--
-- REVIEW_COMMENT_MESSAGE est un CLOB.
-- DBMS_LOB.COMPARE sera utilisé séparément si nécessaire.
-- Ici on recherche d'abord les doublons sur les autres
-- colonnes métier.
-- ============================================================

SELECT
    COUNT(*) AS GROUPES_IDENTIQUES_HORS_CLOB
FROM (
    SELECT
        REVIEW_ID,
        ORDER_ID,
        REVIEW_SCORE,
        REVIEW_COMMENT_TITLE,
        REVIEW_CREATION_DATE,
        REVIEW_ANSWER_TIMESTAMP,
        COUNT(*) AS NB

    FROM BRONZE.REVIEWS_RAW

    GROUP BY
        REVIEW_ID,
        ORDER_ID,
        REVIEW_SCORE,
        REVIEW_COMMENT_TITLE,
        REVIEW_CREATION_DATE,
        REVIEW_ANSWER_TIMESTAMP

    HAVING COUNT(*) > 1
);

-- ============================================================
-- 7. REVIEW_ID ASSOCIES A PLUSIEURS ORDER_ID
--
-- Cas potentiellement plus problématique.
-- ============================================================

SELECT
    COUNT(*) AS REVIEW_ID_MULTI_ORDER
FROM (
    SELECT REVIEW_ID
    FROM BRONZE.REVIEWS_RAW
    GROUP BY REVIEW_ID
    HAVING COUNT(DISTINCT ORDER_ID) > 1
);


-- ============================================================
-- 8. REVIEW_ID AVEC PLUSIEURS SCORES
-- ============================================================

SELECT
    COUNT(*) AS REVIEW_ID_MULTI_SCORE
FROM (
    SELECT REVIEW_ID
    FROM BRONZE.REVIEWS_RAW
    GROUP BY REVIEW_ID
    HAVING COUNT(DISTINCT REVIEW_SCORE) > 1
);


-- ============================================================
-- 9. EXEMPLES DE REVIEW_ID DUPLIQUES
-- ============================================================

SELECT *
FROM (
    SELECT
        REVIEW_ID,
        COUNT(*) AS NB_OCCURRENCES,
        COUNT(DISTINCT ORDER_ID)
            AS NB_ORDERS,
        COUNT(DISTINCT REVIEW_SCORE)
            AS NB_SCORES
    FROM BRONZE.REVIEWS_RAW
    GROUP BY REVIEW_ID
    HAVING COUNT(*) > 1
    ORDER BY COUNT(*) DESC
)
WHERE ROWNUM <= 20;


-- ============================================================
-- 10. COMMANDES AYANT PLUSIEURS AVIS
-- ============================================================

SELECT
    COUNT(*) AS ORDERS_MULTI_REVIEWS
FROM (
    SELECT ORDER_ID
    FROM BRONZE.REVIEWS_RAW
    GROUP BY ORDER_ID
    HAVING COUNT(*) > 1
);