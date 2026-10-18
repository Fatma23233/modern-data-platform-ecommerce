-- ============================================================
-- MODERN DATA PLATFORM - OLIST
-- ETAPE 5.4
-- CHARGEMENT DE GOLD.DIM_DATE
--
-- Periode identifiee dans SILVER :
-- 04/09/2016 -> 12/11/2018
--
-- Grain :
-- 1 ligne = 1 jour
-- ============================================================


-- ============================================================
-- 0. NETTOYAGE
--
-- Permet de relancer le script.
-- A ce stade aucune table de faits n'est encore chargee.
-- ============================================================

DELETE FROM GOLD.DIM_DATE;

COMMIT;


-- ============================================================
-- 1. GENERATION DU CALENDRIER
-- ============================================================

INSERT INTO GOLD.DIM_DATE (
    DATE_KEY,
    FULL_DATE,
    DAY_NUMBER,
    DAY_NAME,
    WEEK_NUMBER,
    MONTH_NUMBER,
    MONTH_NAME,
    QUARTER_NUMBER,
    YEAR_NUMBER
)

WITH DATE_BOUNDS AS (

    SELECT
        TO_DATE('04/09/2016', 'DD/MM/YYYY') AS DATE_MIN,
        TO_DATE('12/11/2018', 'DD/MM/YYYY') AS DATE_MAX
    FROM DUAL

),

CALENDAR AS (

    SELECT
        DATE_MIN + LEVEL - 1 AS FULL_DATE

    FROM DATE_BOUNDS

    CONNECT BY LEVEL <=
        (DATE_MAX - DATE_MIN) + 1
)

SELECT
    TO_NUMBER(
        TO_CHAR(FULL_DATE, 'YYYYMMDD')
    ) AS DATE_KEY,

    FULL_DATE,

    TO_NUMBER(
        TO_CHAR(FULL_DATE, 'DD')
    ) AS DAY_NUMBER,

    TRIM(
        TO_CHAR(
            FULL_DATE,
            'DAY',
            'NLS_DATE_LANGUAGE=FRENCH'
        )
    ) AS DAY_NAME,

    TO_NUMBER(
        TO_CHAR(FULL_DATE, 'IW')
    ) AS WEEK_NUMBER,

    TO_NUMBER(
        TO_CHAR(FULL_DATE, 'MM')
    ) AS MONTH_NUMBER,

    TRIM(
        TO_CHAR(
            FULL_DATE,
            'MONTH',
            'NLS_DATE_LANGUAGE=FRENCH'
        )
    ) AS MONTH_NAME,

    TO_NUMBER(
        TO_CHAR(FULL_DATE, 'Q')
    ) AS QUARTER_NUMBER,

    TO_NUMBER(
        TO_CHAR(FULL_DATE, 'YYYY')
    ) AS YEAR_NUMBER

FROM CALENDAR

ORDER BY FULL_DATE;


COMMIT;


-- ============================================================
-- 2. NOMBRE DE JOURS CHARGES
-- ============================================================

SELECT
    COUNT(*) AS NB_DATES
FROM GOLD.DIM_DATE;


-- ============================================================
-- 3. VERIFICATION DES BORNES
-- ============================================================

SELECT
    MIN(FULL_DATE) AS DATE_MIN,
    MAX(FULL_DATE) AS DATE_MAX
FROM GOLD.DIM_DATE;


-- ============================================================
-- 4. VERIFICATION DES DATE_KEY
-- ============================================================

SELECT
    MIN(DATE_KEY) AS DATE_KEY_MIN,
    MAX(DATE_KEY) AS DATE_KEY_MAX
FROM GOLD.DIM_DATE;


-- ============================================================
-- 5. VERIFICATION DES DOUBLONS
--
-- Doit retourner 0.
-- ============================================================

SELECT
    COUNT(*) AS DATE_KEY_DUPLIQUEES
FROM (
    SELECT DATE_KEY
    FROM GOLD.DIM_DATE
    GROUP BY DATE_KEY
    HAVING COUNT(*) > 1
);


-- ============================================================
-- 6. VERIFICATION DES DATES DUPLIQUEES
--
-- Doit retourner 0.
-- ============================================================

SELECT
    COUNT(*) AS DATES_DUPLIQUEES
FROM (
    SELECT FULL_DATE
    FROM GOLD.DIM_DATE
    GROUP BY FULL_DATE
    HAVING COUNT(*) > 1
);


-- ============================================================
-- 7. APERCU DU DEBUT DU CALENDRIER
-- ============================================================

SELECT *
FROM (
    SELECT
        DATE_KEY,
        FULL_DATE,
        DAY_NUMBER,
        DAY_NAME,
        WEEK_NUMBER,
        MONTH_NUMBER,
        MONTH_NAME,
        QUARTER_NUMBER,
        YEAR_NUMBER
    FROM GOLD.DIM_DATE
    ORDER BY FULL_DATE
)
WHERE ROWNUM <= 10;


-- ============================================================
-- 8. REPARTITION PAR ANNEE
-- ============================================================

SELECT
    YEAR_NUMBER,
    COUNT(*) AS NB_JOURS
FROM GOLD.DIM_DATE
GROUP BY YEAR_NUMBER
ORDER BY YEAR_NUMBER;