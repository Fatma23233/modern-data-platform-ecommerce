-- ============================================================
-- MODERN DATA PLATFORM - OLIST
-- ETAPE 4.7
-- TRANSFORMATION REVIEWS
-- ============================================================


-- ============================================================
-- 0. NETTOYAGE POUR RENDRE LE SCRIPT RELANCABLE
-- ============================================================

DELETE FROM SILVER.REVIEWS;

DELETE FROM SILVER.REJECTED_ROWS
WHERE SOURCE_TABLE = 'REVIEWS_RAW';

COMMIT;


-- ============================================================
-- 1. REV_001
-- SCORE D'AVIS HORS INTERVALLE [1,5]
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
    'REV001-' || REVIEW_ID || '-' || ORDER_ID,

    'REVIEWS_RAW',

    REVIEW_ID || '-' || ORDER_ID,

    BATCH_ID,

    'REV_001',

    'Score avis hors intervalle 1 à 5',

    'review_score IS NULL OR review_score < 1 OR review_score > 5',

    'review_id=' || REVIEW_ID
        || '; order_id=' || ORDER_ID
        || '; review_score='
        || NVL(TO_CHAR(REVIEW_SCORE), 'NULL')

FROM BRONZE.REVIEWS_RAW

WHERE REVIEW_SCORE IS NULL
   OR REVIEW_SCORE < 1
   OR REVIEW_SCORE > 5;


-- ============================================================
-- 2. INSERTION DES AVIS VALIDES
--
-- On ne déduplique PAS sur REVIEW_ID.
-- L'analyse a montré que les review_id répétés correspondent
-- à plusieurs commandes différentes.
-- ============================================================

INSERT INTO SILVER.REVIEWS (
    REVIEW_ID,
    ORDER_ID,
    REVIEW_SCORE,

    REVIEW_COMMENT_TITLE,
    REVIEW_COMMENT_MESSAGE,

    REVIEW_CREATION_DATE,
    REVIEW_ANSWER_TIMESTAMP,

    SOURCE_BATCH_ID
)
SELECT
    B.REVIEW_ID,
    B.ORDER_ID,
    B.REVIEW_SCORE,

    B.REVIEW_COMMENT_TITLE,
    B.REVIEW_COMMENT_MESSAGE,

    CASE
        WHEN B.REVIEW_CREATION_DATE IS NOT NULL
        THEN TO_TIMESTAMP(
            B.REVIEW_CREATION_DATE,
            'YYYY-MM-DD HH24:MI:SS'
        )
    END,

    CASE
        WHEN B.REVIEW_ANSWER_TIMESTAMP IS NOT NULL
        THEN TO_TIMESTAMP(
            B.REVIEW_ANSWER_TIMESTAMP,
            'YYYY-MM-DD HH24:MI:SS'
        )
    END,

    B.BATCH_ID

FROM BRONZE.REVIEWS_RAW B

WHERE NOT EXISTS (

    SELECT 1

    FROM SILVER.REJECTED_ROWS R

    WHERE R.SOURCE_TABLE = 'REVIEWS_RAW'

      AND R.SOURCE_KEY =
          B.REVIEW_ID || '-' || B.ORDER_ID

      AND R.RULE_CODE = 'REV_001'
);


COMMIT;


-- ============================================================
-- 3. VOLUME SILVER
-- ============================================================

SELECT
    COUNT(*) AS SILVER_REVIEWS
FROM SILVER.REVIEWS;


-- ============================================================
-- 4. REJETS
-- ============================================================

SELECT
    RULE_CODE,
    COUNT(*) AS NB_REJETS
FROM SILVER.REJECTED_ROWS
WHERE SOURCE_TABLE = 'REVIEWS_RAW'
GROUP BY RULE_CODE
ORDER BY RULE_CODE;


-- ============================================================
-- 5. VERIFICATION DES REVIEW_ID REPETES
--
-- Ils doivent toujours exister dans SILVER.
-- ============================================================

SELECT
    COUNT(*) AS REVIEW_ID_DUPLIQUES_SILVER
FROM (
    SELECT REVIEW_ID
    FROM SILVER.REVIEWS
    GROUP BY REVIEW_ID
    HAVING COUNT(*) > 1
);


-- ============================================================
-- 6. VERIFICATION DU GRAIN REVIEW_ID + ORDER_ID
--
-- On vérifie s'il existe encore plusieurs lignes pour la même
-- combinaison REVIEW_ID / ORDER_ID.
-- ============================================================

SELECT
    COUNT(*) AS CLES_REVIEW_ORDER_DUPLIQUEES
FROM (
    SELECT
        REVIEW_ID,
        ORDER_ID
    FROM SILVER.REVIEWS
    GROUP BY
        REVIEW_ID,
        ORDER_ID
    HAVING COUNT(*) > 1
);


-- ============================================================
-- 7. RECONCILIATION
-- ============================================================

SELECT
    (
        SELECT COUNT(*)
        FROM BRONZE.REVIEWS_RAW
    ) AS BRONZE_REVIEWS,

    (
        SELECT COUNT(*)
        FROM SILVER.REVIEWS
    ) AS SILVER_REVIEWS,

    (
        SELECT COUNT(DISTINCT SOURCE_KEY)
        FROM SILVER.REJECTED_ROWS
        WHERE SOURCE_TABLE = 'REVIEWS_RAW'
    ) AS REVIEWS_REJETEES

FROM DUAL;