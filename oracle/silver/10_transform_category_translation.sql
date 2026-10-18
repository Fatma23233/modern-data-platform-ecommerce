-- ============================================================
-- MODERN DATA PLATFORM - OLIST
-- ETAPE 4.11
-- TRANSFORMATION CATEGORY_TRANSLATION
--
-- Grain SILVER :
-- 1 ligne = 1 categorie produit
-- ============================================================


-- ============================================================
-- 0. NETTOYAGE
-- Permet de relancer le script
-- ============================================================

DELETE FROM SILVER.CATEGORY_TRANSLATION;

DELETE FROM SILVER.REJECTED_ROWS
WHERE SOURCE_TABLE = 'CATEGORY_TRANSLATION_RAW';

COMMIT;


-- ============================================================
-- 1. INSERTION DES TRADUCTIONS
--
-- Normalisation :
-- - suppression des espaces inutiles
-- - noms conserves en minuscules
-- ============================================================

INSERT INTO SILVER.CATEGORY_TRANSLATION (
    PRODUCT_CATEGORY_NAME,
    PRODUCT_CATEGORY_NAME_ENGLISH,
    SOURCE_BATCH_ID
)
SELECT
    LOWER(TRIM(PRODUCT_CATEGORY_NAME)),
    LOWER(TRIM(PRODUCT_CATEGORY_NAME_ENGLISH)),
    BATCH_ID

FROM BRONZE.CATEGORY_TRANSLATION_RAW

WHERE PRODUCT_CATEGORY_NAME IS NOT NULL
  AND PRODUCT_CATEGORY_NAME_ENGLISH IS NOT NULL;


COMMIT;


-- ============================================================
-- 2. VOLUME SILVER
-- ============================================================

SELECT
    COUNT(*) AS SILVER_CATEGORY_TRANSLATION
FROM SILVER.CATEGORY_TRANSLATION;


-- ============================================================
-- 3. CATEGORIES DISTINCTES
-- ============================================================

SELECT
    COUNT(DISTINCT PRODUCT_CATEGORY_NAME)
        AS CATEGORIES_DISTINCTES
FROM SILVER.CATEGORY_TRANSLATION;


-- ============================================================
-- 4. VERIFICATION DES DOUBLONS
-- ============================================================

SELECT
    COUNT(*) AS CATEGORIES_DUPLIQUEES
FROM (

    SELECT
        PRODUCT_CATEGORY_NAME

    FROM SILVER.CATEGORY_TRANSLATION

    GROUP BY
        PRODUCT_CATEGORY_NAME

    HAVING COUNT(*) > 1
);


-- ==============*==================================*==========
-- 5. VERIFICATION DES *ALEURS NULL
-- ============================================================

SELECT
    SUM(
        CASE
            WHEN PRODUCT_CATEGORY_NAME IS NULL
            THEN 1
            ELSE 0
        END
    ) AS CATEGORY_NULL,

    SUM(
        CASE
            WHEN PRODUCT_CATEGORY_NAME_ENGLISH IS NULL
            THEN 1
            ELSE 0
        END
    ) AS TRANSLATION_NULL

FROM SILVER.CATEGORY_TRANSLATION;


-- ============================================================
-- 6. RECONCILIATION BRONZE / SILVER
-- ============================================================

SELECT

    (
        SELECT COUNT(*)
        FROM BRONZE.CATEGORY_TRANSLATION_RAW
    ) AS BRONZE_CATEGORIES,

    (
        SELECT COUNT(*)
        FROM SILVER.CATEGORY_TRANSLATION
    ) AS SILVER_CATEGORIES

FROM DUAL;


-- ============================================================
-- 7. CONTROLE DES CATEGORIES PRODUCTS SANS TRADUCTION
--
-- Ces categories ne sont PAS rejetees.
-- Elles restent dans SILVER.PRODUCTS avec
-- PRODUCT_CATEGORY_ENGLISH = NULL.
-- ============================================================

SELECT
    PRODUCT_CATEGORY_NAME,
    COUNT(*) AS NB_PRODUITS

FROM SILVER.PRODUCTS

WHERE PRODUCT_CATEGORY_NAME IS NOT NULL
  AND PRODUCT_CATEGORY_ENGLISH IS NULL

GROUP BY
    PRODUCT_CATEGORY_NAME

ORDER BY
    PRODUCT_CATEGORY_NAME;