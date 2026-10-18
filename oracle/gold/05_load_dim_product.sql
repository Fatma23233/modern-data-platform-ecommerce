-- ============================================================
-- MODERN DATA PLATFORM - OLIST
-- GOLD
-- 05_load_dim_product.sql
--
-- CHARGEMENT DE GOLD.DIM_PRODUCT
--
-- Grain :
-- 1 ligne = 1 PRODUCT_ID
--
-- Source :
-- SILVER.PRODUCTS
--
-- Volume SILVER valide :
-- 32 947 produits
-- ============================================================


-- ============================================================
-- 0. NETTOYAGE
--
-- Permet de relancer le script.
-- Les tables de faits ne sont pas encore chargees.
-- ============================================================

DELETE FROM GOLD.DIM_PRODUCT;

COMMIT;


-- ============================================================
-- 1. CHARGEMENT DE DIM_PRODUCT
--
-- PRODUCT_KEY :
-- surrogate key GOLD generee de maniere deterministe
-- en ordonnant les produits par PRODUCT_ID.
-- ============================================================

INSERT INTO GOLD.DIM_PRODUCT (
    PRODUCT_KEY,
    PRODUCT_ID,
    PRODUCT_CATEGORY_NAME,
    PRODUCT_CATEGORY_ENGLISH,
    PRODUCT_NAME_LENGTH,
    PRODUCT_DESCRIPTION_LENGTH,
    PRODUCT_PHOTOS_QTY,
    PRODUCT_WEIGHT_G,
    PRODUCT_LENGTH_CM,
    PRODUCT_HEIGHT_CM,
    PRODUCT_WIDTH_CM
)
SELECT
    ROW_NUMBER() OVER (
        ORDER BY P.PRODUCT_ID
    ) AS PRODUCT_KEY,

    P.PRODUCT_ID,

    P.PRODUCT_CATEGORY_NAME,

    P.PRODUCT_CATEGORY_ENGLISH,

    P.PRODUCT_NAME_LENGTH,

    P.PRODUCT_DESCRIPTION_LENGTH,

    P.PRODUCT_PHOTOS_QTY,

    P.PRODUCT_WEIGHT_G,

    P.PRODUCT_LENGTH_CM,

    P.PRODUCT_HEIGHT_CM,

    P.PRODUCT_WIDTH_CM

FROM SILVER.PRODUCTS P;


COMMIT;


-- ============================================================
-- 2. VOLUME TOTAL GOLD
--
-- Attendu :
-- 32 947
-- ============================================================

SELECT
    COUNT(*) AS NB_PRODUCTS
FROM GOLD.DIM_PRODUCT;


-- ============================================================
-- 3. NOMBRE DE PRODUCT_ID DISTINCTS
--
-- Attendu :
-- 32 947
-- ============================================================

SELECT
    COUNT(DISTINCT PRODUCT_ID)
        AS PRODUCTS_DISTINCTS
FROM GOLD.DIM_PRODUCT;


-- ============================================================
-- 4. VERIFICATION DES SURROGATE KEYS
--
-- Attendu :
-- KEY_MIN = 1
-- KEY_MAX = 32 947
-- ============================================================

SELECT
    MIN(PRODUCT_KEY) AS KEY_MIN,
    MAX(PRODUCT_KEY) AS KEY_MAX

FROM GOLD.DIM_PRODUCT;


-- ============================================================
-- 5. VERIFICATION DES PRODUCT_KEY DUPLIQUEES
--
-- Doit retourner 0.
-- ============================================================

SELECT
    COUNT(*) AS PRODUCT_KEY_DUPLIQUEES

FROM (
    SELECT
        PRODUCT_KEY

    FROM GOLD.DIM_PRODUCT

    GROUP BY
        PRODUCT_KEY

    HAVING COUNT(*) > 1
);


-- ============================================================
-- 6. VERIFICATION DES PRODUCT_ID DUPLIQUES
--
-- Doit retourner 0.
-- ============================================================

SELECT
    COUNT(*) AS PRODUCT_ID_DUPLIQUES

FROM (
    SELECT
        PRODUCT_ID

    FROM GOLD.DIM_PRODUCT

    GROUP BY
        PRODUCT_ID

    HAVING COUNT(*) > 1
);


-- ============================================================
-- 7. VERIFICATION DES PRODUCT_ID NULL
--
-- Doit retourner 0.
-- ============================================================

SELECT
    COUNT(*) AS PRODUCT_ID_NULL

FROM GOLD.DIM_PRODUCT

WHERE PRODUCT_ID IS NULL;


-- ============================================================
-- 8. PRODUITS SANS TRADUCTION ANGLAISE
--
-- On ne rejette pas ces produits.
--
-- Notre analyse SILVER avait identifie :
--
-- pc_gamer
--     3 produits
--
-- portateis_cozinha_e_preparadores_de_alimentos
--     10 produits
--
-- Total attendu :
--     13 produits
-- ============================================================

SELECT
    COUNT(*) AS PRODUCTS_SANS_TRADUCTION

FROM GOLD.DIM_PRODUCT

WHERE PRODUCT_CATEGORY_NAME IS NOT NULL
  AND PRODUCT_CATEGORY_ENGLISH IS NULL;


-- ============================================================
-- 9. DETAIL DES CATEGORIES SANS TRADUCTION
-- ============================================================

SELECT
    PRODUCT_CATEGORY_NAME,
    COUNT(*) AS NB_PRODUCTS

FROM GOLD.DIM_PRODUCT

WHERE PRODUCT_CATEGORY_NAME IS NOT NULL
  AND PRODUCT_CATEGORY_ENGLISH IS NULL

GROUP BY
    PRODUCT_CATEGORY_NAME

ORDER BY
    PRODUCT_CATEGORY_NAME;


-- ============================================================
-- 10. PRODUITS AVEC POIDS INVALIDE
--
-- Les produits ayant un poids <= 0 ont deja ete
-- rejetes dans SILVER avec PRD_001.
--
-- Doit retourner 0.
-- ============================================================

SELECT
    COUNT(*) AS PRODUCTS_POIDS_INVALIDE

FROM GOLD.DIM_PRODUCT

WHERE PRODUCT_WEIGHT_G IS NOT NULL
  AND PRODUCT_WEIGHT_G <= 0;


-- ============================================================
-- 11. CONTROLE DES DIMENSIONS PHYSIQUES NEGATIVES
--
-- On verifie qu'aucune dimension produit n'est negative.
-- ============================================================

SELECT
    COUNT(*) AS PRODUCTS_DIMENSIONS_INVALIDES

FROM GOLD.DIM_PRODUCT

WHERE
       (PRODUCT_LENGTH_CM IS NOT NULL
        AND PRODUCT_LENGTH_CM < 0)

    OR (PRODUCT_HEIGHT_CM IS NOT NULL
        AND PRODUCT_HEIGHT_CM < 0)

    OR (PRODUCT_WIDTH_CM IS NOT NULL
        AND PRODUCT_WIDTH_CM < 0);


-- ============================================================
-- 12. CONTROLE DU NOMBRE DE PHOTOS
--
-- Une quantite negative serait incoherente.
-- ============================================================

SELECT
    COUNT(*) AS PRODUCTS_PHOTOS_INVALIDES

FROM GOLD.DIM_PRODUCT

WHERE PRODUCT_PHOTOS_QTY IS NOT NULL
  AND PRODUCT_PHOTOS_QTY < 0;


-- ============================================================
-- 13. RECONCILIATION SILVER / GOLD
--
-- On doit avoir :
--
-- SILVER_PRODUCTS = GOLD_PRODUCTS = 32 947
-- ============================================================

SELECT

    (
        SELECT COUNT(*)
        FROM SILVER.PRODUCTS
    ) AS SILVER_PRODUCTS,

    (
        SELECT COUNT(*)
        FROM GOLD.DIM_PRODUCT
    ) AS GOLD_PRODUCTS,

    (
        SELECT COUNT(*)
        FROM SILVER.PRODUCTS
    )
    -
    (
        SELECT COUNT(*)
        FROM GOLD.DIM_PRODUCT
    ) AS ECART

FROM DUAL;


-- ============================================================
-- 14. APERCU DE DIM_PRODUCT
-- ============================================================

SELECT *
FROM (

    SELECT
        PRODUCT_KEY,
        PRODUCT_ID,
        PRODUCT_CATEGORY_NAME,
        PRODUCT_CATEGORY_ENGLISH,
        PRODUCT_WEIGHT_G,
        PRODUCT_LENGTH_CM,
        PRODUCT_HEIGHT_CM,
        PRODUCT_WIDTH_CM

    FROM GOLD.DIM_PRODUCT

    ORDER BY PRODUCT_KEY

)
WHERE ROWNUM <= 20;


-- ============================================================
-- 15. SYNTHESE FINALE
-- ============================================================

SELECT
    COUNT(*) AS TOTAL_PRODUCTS,

    COUNT(DISTINCT PRODUCT_ID)
        AS PRODUCT_ID_UNIQUES,

    SUM(
        CASE
            WHEN PRODUCT_CATEGORY_NAME IS NOT NULL
             AND PRODUCT_CATEGORY_ENGLISH IS NULL
            THEN 1
            ELSE 0
        END
    ) AS SANS_TRADUCTION,

    SUM(
        CASE
            WHEN PRODUCT_WEIGHT_G IS NOT NULL
             AND PRODUCT_WEIGHT_G <= 0
            THEN 1
            ELSE 0
        END
    ) AS POIDS_INVALIDES

FROM GOLD.DIM_PRODUCT;