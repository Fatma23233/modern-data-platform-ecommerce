-- ============================================================
-- ETAPE 4.9
-- ANALYSE DE BRONZE.GEOLOCATION_RAW
-- AUCUNE DONNEE N'EST MODIFIEE
-- ============================================================


-- ============================================================
-- 1. VOLUME TOTAL
-- ============================================================

SELECT
    COUNT(*) AS TOTAL_GEO
FROM BRONZE.GEOLOCATION_RAW;


-- ============================================================
-- 2. NOMBRE DE CODES POSTAUX DISTINCTS
-- ============================================================

SELECT
    COUNT(DISTINCT GEOLOCATION_ZIP_CODE_PREFIX)
        AS ZIP_DISTINCTS
FROM BRONZE.GEOLOCATION_RAW;


-- ============================================================
-- 3. CODES POSTAUX AYANT PLUSIEURS LIGNES
-- ============================================================

SELECT
    COUNT(*) AS ZIP_AVEC_PLUSIEURS_LIGNES
FROM (
    SELECT GEOLOCATION_ZIP_CODE_PREFIX
    FROM BRONZE.GEOLOCATION_RAW
    GROUP BY GEOLOCATION_ZIP_CODE_PREFIX
    HAVING COUNT(*) > 1
);


-- ============================================================
-- 4. NOMBRE DE DOUBLONS EXACTS
--
-- Ici toutes les colonnes métier sont comparables.
-- ============================================================

SELECT
    COUNT(*) AS GROUPES_DOUBLONS_EXACTS,
    SUM(NB - 1) AS LIGNES_DUPLICATIVES
FROM (
    SELECT
        GEOLOCATION_ZIP_CODE_PREFIX,
        GEOLOCATION_LAT,
        GEOLOCATION_LNG,
        GEOLOCATION_CITY,
        GEOLOCATION_STATE,
        COUNT(*) AS NB

    FROM BRONZE.GEOLOCATION_RAW

    GROUP BY
        GEOLOCATION_ZIP_CODE_PREFIX,
        GEOLOCATION_LAT,
        GEOLOCATION_LNG,
        GEOLOCATION_CITY,
        GEOLOCATION_STATE

    HAVING COUNT(*) > 1
);


-- ============================================================
-- 5. ZIP AYANT PLUSIEURS VILLES
-- ============================================================

SELECT
    COUNT(*) AS ZIP_MULTI_VILLES
FROM (
    SELECT GEOLOCATION_ZIP_CODE_PREFIX
    FROM BRONZE.GEOLOCATION_RAW
    GROUP BY GEOLOCATION_ZIP_CODE_PREFIX
    HAVING COUNT(
        DISTINCT LOWER(TRIM(GEOLOCATION_CITY))
    ) > 1
);


-- ============================================================
-- 6. ZIP AYANT PLUSIEURS ETATS
-- ============================================================

SELECT
    COUNT(*) AS ZIP_MULTI_ETATS
FROM (
    SELECT GEOLOCATION_ZIP_CODE_PREFIX
    FROM BRONZE.GEOLOCATION_RAW
    GROUP BY GEOLOCATION_ZIP_CODE_PREFIX
    HAVING COUNT(
        DISTINCT UPPER(TRIM(GEOLOCATION_STATE))
    ) > 1
);


-- ============================================================
-- 7. ZIP AYANT PLUSIEURS COORDONNEES
-- ============================================================

SELECT
    COUNT(*) AS ZIP_MULTI_COORDONNEES
FROM (
    SELECT GEOLOCATION_ZIP_CODE_PREFIX
    FROM BRONZE.GEOLOCATION_RAW
    GROUP BY GEOLOCATION_ZIP_CODE_PREFIX
    HAVING COUNT(
        DISTINCT TO_CHAR(GEOLOCATION_LAT)
                 || '|'
                 || TO_CHAR(GEOLOCATION_LNG)
    ) > 1
);


-- ============================================================
-- 8. ZIP LES PLUS REPRESENTES
-- ============================================================

SELECT *
FROM (
    SELECT
        GEOLOCATION_ZIP_CODE_PREFIX,
        COUNT(*) AS NB_LIGNES,

        COUNT(
            DISTINCT LOWER(TRIM(GEOLOCATION_CITY))
        ) AS NB_VILLES,

        COUNT(
            DISTINCT UPPER(TRIM(GEOLOCATION_STATE))
        ) AS NB_ETATS

    FROM BRONZE.GEOLOCATION_RAW

    GROUP BY GEOLOCATION_ZIP_CODE_PREFIX

    ORDER BY COUNT(*) DESC
)
WHERE ROWNUM <= 20;