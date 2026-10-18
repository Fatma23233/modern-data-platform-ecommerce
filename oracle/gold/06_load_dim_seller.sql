-- ============================================================
-- MODERN DATA PLATFORM - OLIST
-- GOLD
-- 06_load_dim_seller.sql
--
-- CHARGEMENT DE GOLD.DIM_SELLER
--
-- Grain :
-- 1 ligne = 1 SELLER_ID
--
-- Source :
-- SILVER.SELLERS
--
-- Volume attendu :
-- 3 095 vendeurs
--
-- Gestion geographique :
-- - ZIP trouve : GEOGRAPHY_KEY correspondante
-- - ZIP absent : GEOGRAPHY_KEY = 0
-- ============================================================


-- ============================================================
-- 0. NETTOYAGE
--
-- Le script peut etre relance tant que les tables de faits
-- ne sont pas encore chargees.
-- ============================================================

DELETE FROM GOLD.DIM_SELLER;

COMMIT;


-- ============================================================
-- 1. CHARGEMENT DE DIM_SELLER
--
-- SELLER_KEY :
-- surrogate key generee avec ROW_NUMBER.
--
-- LEFT JOIN :
-- conserve tous les vendeurs.
--
-- Si le ZIP n'existe pas dans DIM_GEOGRAPHY :
-- GEOGRAPHY_KEY = 0
-- ============================================================

INSERT INTO GOLD.DIM_SELLER (
    SELLER_KEY,
    SELLER_ID,
    SELLER_ZIP_CODE_PREFIX,
    SELLER_CITY,
    SELLER_STATE,
    GEOGRAPHY_KEY
)
SELECT
    ROW_NUMBER() OVER (
        ORDER BY S.SELLER_ID
    ) AS SELLER_KEY,

    S.SELLER_ID,

    S.SELLER_ZIP_CODE_PREFIX,

    S.SELLER_CITY,

    S.SELLER_STATE,

    NVL(
        G.GEOGRAPHY_KEY,
        0
    ) AS GEOGRAPHY_KEY

FROM SILVER.SELLERS S

LEFT JOIN GOLD.DIM_GEOGRAPHY G
    ON G.ZIP_CODE_PREFIX = S.SELLER_ZIP_CODE_PREFIX;


COMMIT;


-- ============================================================
-- 2. VOLUME TOTAL
--
-- Attendu :
-- 3 095
-- ============================================================

SELECT
    COUNT(*) AS NB_SELLERS
FROM GOLD.DIM_SELLER;


-- ============================================================
-- 3. SELLER_ID DISTINCTS
--
-- Attendu :
-- 3 095
-- ============================================================

SELECT
    COUNT(DISTINCT SELLER_ID) AS SELLERS_DISTINCTS
FROM GOLD.DIM_SELLER;


-- ============================================================
-- 4. VERIFICATION DES SURROGATE KEYS
--
-- Attendu :
-- KEY_MIN = 1
-- KEY_MAX = 3 095
-- ============================================================

SELECT
    MIN(SELLER_KEY) AS KEY_MIN,
    MAX(SELLER_KEY) AS KEY_MAX
FROM GOLD.DIM_SELLER;


-- ============================================================
-- 5. SELLER_KEY DUPLIQUEES
--
-- Doit retourner 0.
-- ============================================================

SELECT
    COUNT(*) AS SELLER_KEY_DUPLIQUEES
FROM (
    SELECT
        SELLER_KEY
    FROM GOLD.DIM_SELLER
    GROUP BY
        SELLER_KEY
    HAVING COUNT(*) > 1
);


-- ============================================================
-- 6. SELLER_ID DUPLIQUES
--
-- Doit retourner 0.
-- ============================================================

SELECT
    COUNT(*) AS SELLER_ID_DUPLIQUES
FROM (
    SELECT
        SELLER_ID
    FROM GOLD.DIM_SELLER
    GROUP BY
        SELLER_ID
    HAVING COUNT(*) > 1
);


-- ============================================================
-- 7. SELLER_ID NULL
--
-- Doit retourner 0.
-- ============================================================

SELECT
    COUNT(*) AS SELLER_ID_NULL
FROM GOLD.DIM_SELLER
WHERE SELLER_ID IS NULL;


-- ============================================================
-- 8. VENDEURS AVEC GEO UNKNOWN
--
-- GEOGRAPHY_KEY = 0 correspond a la ligne UNKNOWN
-- de DIM_GEOGRAPHY.
--
-- D'apres notre premiere execution :
-- attendu = 7
-- ============================================================

SELECT
    COUNT(*) AS SELLERS_GEO_UNKNOWN
FROM GOLD.DIM_SELLER
WHERE GEOGRAPHY_KEY = 0;


-- ============================================================
-- 9. ZIP DISTINCTS SANS GEOLOCALISATION
--
-- Notre audit SILVER avait trouve 7 ZIP.
--
-- Attendu :
-- 7
-- ============================================================

SELECT
    COUNT(
        DISTINCT SELLER_ZIP_CODE_PREFIX
    ) AS ZIP_UNKNOWN
FROM GOLD.DIM_SELLER
WHERE GEOGRAPHY_KEY = 0;


-- ============================================================
-- 10. VENDEURS AVEC GEOLOCALISATION CONNUE
--
-- D'apres notre premiere execution :
-- attendu = 3 088
-- ============================================================

SELECT
    COUNT(*) AS SELLERS_GEO_CONNUE
FROM GOLD.DIM_SELLER
WHERE GEOGRAPHY_KEY <> 0;


-- ============================================================
-- 11. CONTROLE DES REFERENCES VERS DIM_GEOGRAPHY
--
-- Chaque GEOGRAPHY_KEY de DIM_SELLER doit exister
-- dans GOLD.DIM_GEOGRAPHY.
--
-- Doit retourner 0.
-- ============================================================

SELECT
    COUNT(*) AS SELLERS_SANS_DIM_GEO
FROM GOLD.DIM_SELLER S
WHERE NOT EXISTS (
    SELECT 1
    FROM GOLD.DIM_GEOGRAPHY G
    WHERE G.GEOGRAPHY_KEY = S.GEOGRAPHY_KEY
);


-- ============================================================
-- 12. RECONCILIATION SILVER / GOLD
--
-- Attendu :
--
-- SILVER_SELLERS = 3 095
-- GOLD_SELLERS   = 3 095
-- ECART          = 0
-- ============================================================

SELECT
    (
        SELECT COUNT(*)
        FROM SILVER.SELLERS
    ) AS SILVER_SELLERS,

    (
        SELECT COUNT(*)
        FROM GOLD.DIM_SELLER
    ) AS GOLD_SELLERS,

    (
        SELECT COUNT(*)
        FROM SILVER.SELLERS
    )
    -
    (
        SELECT COUNT(*)
        FROM GOLD.DIM_SELLER
    ) AS ECART

FROM DUAL;


-- ============================================================
-- 13. DETAIL DES VENDEURS AVEC GEO UNKNOWN
--
-- Permet de verifier les vendeurs affectes
-- a la ligne technique GEOGRAPHY_KEY = 0.
-- ============================================================

SELECT
    SELLER_KEY,
    SELLER_ID,
    SELLER_ZIP_CODE_PREFIX,
    SELLER_CITY,
    SELLER_STATE,
    GEOGRAPHY_KEY

FROM GOLD.DIM_SELLER

WHERE GEOGRAPHY_KEY = 0

ORDER BY
    SELLER_ZIP_CODE_PREFIX,
    SELLER_ID;


-- ============================================================
-- 14. REPARTITION GEO CONNUE / UNKNOWN
-- ============================================================

SELECT
    CASE
        WHEN GEOGRAPHY_KEY = 0 THEN 'UNKNOWN'
        ELSE 'KNOWN'
    END AS GEO_STATUS,

    COUNT(*) AS NB_SELLERS

FROM GOLD.DIM_SELLER

GROUP BY
    CASE
        WHEN GEOGRAPHY_KEY = 0 THEN 'UNKNOWN'
        ELSE 'KNOWN'
    END

ORDER BY GEO_STATUS;


-- ============================================================
-- 15. SYNTHESE FINALE
--
-- Permet de valider toute la dimension en une requete.
-- ============================================================

SELECT
    COUNT(*) AS TOTAL_SELLERS,

    COUNT(DISTINCT SELLER_ID)
        AS SELLER_ID_UNIQUES,

    SUM(
        CASE
            WHEN GEOGRAPHY_KEY = 0
            THEN 1
            ELSE 0
        END
    ) AS GEO_UNKNOWN,

    SUM(
        CASE
            WHEN GEOGRAPHY_KEY <> 0
            THEN 1
            ELSE 0
        END
    ) AS GEO_CONNUE

FROM GOLD.DIM_SELLER;