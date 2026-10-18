-- ============================================================
-- MODERN DATA PLATFORM - OLIST
-- ETAPE 4.10
-- TRANSFORMATION GEOLOCATION
--
-- Grain SILVER :
-- 1 ligne = 1 GEOLOCATION_ZIP_CODE_PREFIX
-- ============================================================


-- ============================================================
-- 0. NETTOYAGE
-- ============================================================

DELETE FROM SILVER.GEOLOCATION;

DELETE FROM SILVER.REJECTED_ROWS
WHERE SOURCE_TABLE = 'GEOLOCATION_RAW';

COMMIT;


-- ============================================================
-- 1. CONSOLIDATION GEOLOCATION
--
-- Pour chaque ZIP :
--
-- LAT / LNG = moyenne des coordonnées
--
-- CITY = ville la plus fréquente
-- STATE = état le plus fréquent
--
-- En cas d'égalité :
-- ordre alphabétique pour rendre le résultat déterministe.
-- ============================================================

INSERT INTO SILVER.GEOLOCATION (
    GEOLOCATION_ZIP_CODE_PREFIX,
    GEOLOCATION_LAT,
    GEOLOCATION_LNG,
    GEOLOCATION_CITY,
    GEOLOCATION_STATE,
    SOURCE_BATCH_ID
)

WITH

-- ------------------------------------------------------------
-- COORDONNEES MOYENNES
-- ------------------------------------------------------------

COORDS AS (

    SELECT
        GEOLOCATION_ZIP_CODE_PREFIX,

        AVG(GEOLOCATION_LAT)
            AS AVG_LAT,

        AVG(GEOLOCATION_LNG)
            AS AVG_LNG,

        MAX(BATCH_ID)
            AS SOURCE_BATCH_ID

    FROM BRONZE.GEOLOCATION_RAW

    GROUP BY GEOLOCATION_ZIP_CODE_PREFIX
),


-- ------------------------------------------------------------
-- FREQUENCE DES VILLES
-- ------------------------------------------------------------

CITY_COUNTS AS (

    SELECT
        GEOLOCATION_ZIP_CODE_PREFIX,

        LOWER(TRIM(GEOLOCATION_CITY))
            AS GEOLOCATION_CITY,

        COUNT(*) AS NB

    FROM BRONZE.GEOLOCATI*N_RAW

    WHERE GEOLOCATION_CITY *S NOT NULL

    GROUP BY
        G*OLOCATION_ZIP_CODE_PREFIX,
       *LOWER(TRIM(GEOLOCATION_CITY))
),

*-- -------------------------------*----------------------------
-- VI*LE MAJORITAIRE
-- ----------------*----------------------------------*--------

CITY_RANKED AS (

    SE*ECT
        GEOLOCATION_ZIP_CODE_P*EFIX,
        GEOLOCATION_CITY,

 *      ROW_NUMBER() OVER (
            PARTITION BY GEOLOCATION_ZIP_CODE_PREFIX
            ORDER BY
                NB DESC,
                GEOLOCATION_CITY ASC
        ) AS RN

    FROM CITY_COUNTS
),


-- ------------------------------------------------------------
-- FREQUENCE DES ETATS
-- ------------------------------------------------------------

STATE_COUNTS AS (

    SELECT
        GEOLOCATION_ZIP_CODE_PREFIX,

        UPPER(TRIM(GEOLOCATION_STATE))
            AS GEOLOCATION_STATE,

        COUNT(*) AS NB

    FROM BRONZE.GEOLOCATION_RAW

    WHERE GEOLOCATION_STATE IS NOT NULL

    GROUP BY
        GEOLOCATION_ZIP_CODE_PREFIX,
        UPPER(TRIM(GEOLOCATION_STATE))
),


-- ------------------------------------------------------------
-- ETAT MAJORITAIRE
-- ------------------------------------------------------------

STATE_RANKED AS (

    SELECT
        GEOLOCATION_ZIP_CODE_PREFIX,
        GEOLOCATION_STATE,

        ROW_NUMBER() OVER (
            PARTITION BY GEOLOCATION_ZIP_CODE_PREFIX
            ORDER BY
                NB DESC,
                GEOLOCATION_STATE ASC
        ) AS RN

    FROM STATE_COUNTS
)


-- ============================================================
-- INSERTION FINALE
-- ============================================================

SELECT
    C.GEOLOCATION_ZIP_CODE_PREFIX,

    C.AVG_LAT,

    C.AVG_LNG,

    CITY.GEOLOCATION_CITY,

    STATE.GEOLOCATION_STATE,

    C.SOURCE_BATCH_ID

FROM COORDS C

LEFT JOIN CITY_RANKED CITY
    ON CITY.GEOLOCATION_ZIP_CODE_PREFIX =
       C.GEOLOCATION_ZIP_CODE_PREFIX
    AND CITY.RN = 1

LEFT JOIN STATE_RANKED STATE
    ON STATE.GEOLOCATION_ZIP_CODE_PREFIX =
       C.GEOLOCATION_ZIP_CODE_PREFIX
    AND STATE.RN = 1;


COMMIT;


-- ============================================================
-- 2. VOLUME SILVER
-- ============================================================

SELECT
    COUNT(*) AS SILVER_GEO
FROM SILVER.GEOLOCATION;


-- ============================================================
-- 3. NOMBRE DE ZIP DISTINCTS
-- ============================================================

SELECT
    COUNT(DISTINCT GEOLOCATION_ZIP_CODE_PREFIX)
        AS ZIP_DISTINCTS_SILVER
FROM SILVER.GEOLOCATION;


-- ============================================================
-- 4. VERIFICATION ABSENCE DE ZIP DUPLIQUES
-- ============================================================

SELECT
    COUNT(*) AS ZIP_DUPLIQUES_SILVER
FROM (

    SELECT
        GEOLOCATION_ZIP_CODE_PREFIX

    FROM SILVER.GEOLOCATION

    GROUP BY GEOLOCATION_ZIP_CODE_PREFIX

    HAVING COUNT(*) > 1
);


-- ====================*==================================*====
-- 5. VERIFICATION DES 8 ZIP *ULTI-ETATS
-- ============================================================

SELECT
    GEOLOCATION_ZIP_CODE_PREFIX,
    GEOLOCATION_CITY,
    GEOLOCATION_STATE,
    GEOLOCATION_LAT,
    GEOLOCATION_LNG

FROM SILVER.GEOLOCATION

WHERE GEOLOCATION_ZIP_CODE_PREFIX IN (
    2116,
    4011,
    21550,
    23056,
    72915,
    78557,
    79750,
    80630
)

ORDER BY GEOLOCATION_ZIP_CODE_PREFIX;


-- ============================================================
-- 6. CONTROLE DE CONSOLIDATION
-- ============================================================

SELECT
    (
        SELECT COUNT(*)
        FROM BRONZE.GEOLOCATION_RAW
    ) AS BRONZE_LIGNES,

    (
        SELECT COUNT(
            DISTINCT GEOLOCATION_ZIP_CODE_PREFIX
        )
        FROM BRONZE.GEOLOCATION_RAW
    ) AS BRONZE_ZIP,

    (
        SELECT COUNT(*)
        FROM SILVER.GEOLOCATION
    ) AS SILVER_LIGNES,

    (
        SELECT COUNT(
            DISTINCT GEOLOCATION_ZIP_CODE_PREFIX
        )
        FROM SILVER.GEOLOCATION
    ) AS SILVER_ZIP

FROM DUAL;