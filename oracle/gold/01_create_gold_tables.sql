-- ============================================================
-- MODERN DATA PLATFORM - OLIST
-- ETAPE 5.3
-- CREATION DES TABLES GOLD
--
-- Architecture :
-- 5 dimensions
-- 4 tables de faits
-- ============================================================


-- ============================================================
-- 1. DIM_DATE
--
-- Grain :
-- 1 ligne = 1 jour
-- ============================================================

CREATE TABLE GOLD.DIM_DATE (

    DATE_KEY            NUMBER(8)       NOT NULL,
    FULL_DATE           DATE            NOT NULL,

    DAY_NUMBER          NUMBER(2)       NOT NULL,
    DAY_NAME            VARCHAR2(20),

    WEEK_NUMBER         NUMBER(2),

    MONTH_NUMBER        NUMBER(2)       NOT NULL,
    MONTH_NAME          VARCHAR2(20),

    QUARTER_NUMBER      NUMBER(1)       NOT NULL,
    YEAR_NUMBER         NUMBER(4)       NOT NULL,

    CONSTRAINT PK_GOLD_DIM_DATE
        PRIMARY KEY (DATE_KEY),

    CONSTRAINT UK_GOLD_DIM_DATE
        UNIQUE (FULL_DATE),

    CONSTRAINT CK_GOLD_DATE_MONTH
        CHECK (MONTH_NUMBER BETWEEN 1 AND 12),

    CONSTRAINT CK_GOLD_DATE_QUARTER
        CHECK (QUARTER_NUMBER BETWEEN 1 AND 4)
);


-- ============================================================
-- 2. DIM_GEOGRAPHY
--
-- Grain :
-- 1 ligne = 1 code postal
--
-- GEOGRAPHY_KEY = surrogate key
--
-- Une ligne UNKNOWN sera ajoutee lors du chargement
-- pour les ZIP absents de SILVER.GEOLOCATION.
-- ============================================================

CREATE TABLE GOLD.DIM_GEOGRAPHY (

    GEOGRAPHY_KEY      NUMBER          NOT NULL,

    ZIP_CODE_PREFIX    NUMBER,

    CITY               VARCHAR2(255),
    STATE              VARCHAR2(10),

    LATITUDE           NUMBER,
    LONGITUDE          NUMBER,

    CONSTRAINT PK_GOLD_DIM_GEOGRAPHY
        PRIMARY KEY (GEOGRAPHY_KEY),

    CONSTRAINT UK_GOLD_DIM_GEOGRAPHY_ZIP
        UNIQUE (ZIP_CODE_PREFIX)
);


-- ============================================================
-- 3. DIM_CUSTOMER
--
-- Grain :
-- 1 ligne = 1 CUSTOMER_ID
-- ============================================================

CREATE TABLE GOLD.DIM_CUSTOMER (

    CUSTOMER_KEY              NUMBER          NOT NULL,

    CUSTOMER_ID               VARCHAR2(50)    NOT NULL,
    CUSTOMER_UNIQUE_ID        VARCHAR2(50)    NOT NULL,

    CUSTOMER_ZIP_CODE_PREFIX  NUMBER,

    CUSTOMER_CITY             VARCHAR2(255),
    CUSTOMER_STATE            VARCHAR2(10),

    GEOGRAPHY_KEY             NUMBER          NOT NULL,

    CONSTRAINT PK_GOLD_DIM_CUSTOMER
        PRIMARY KEY (CUSTOMER_KEY),

    CONSTRAINT UK_GOLD_DIM_CUSTOMER_ID
        UNIQUE (CUSTOMER_ID),

    CONSTRAINT FK_CUSTOMER_GEOGRAPHY
        FOREIGN KEY (GEOGRAPHY_KEY)
        REFERENCES GOLD.DIM_GEOGRAPHY (GEOGRAPHY_KEY)
);


-- ============================================================
-- 4. DIM_PRODUCT
--
-- Grain :
-- 1 ligne = 1 PRODUCT_ID
-- ============================================================

CREATE TABLE GOLD.DIM_PRODUCT (

    PRODUCT_KEY                  NUMBER          NOT NULL,

    PRODUCT_ID                   VARCHAR2(50)    NOT NULL,

    PRODUCT_CATEGORY_NAME        VARCHAR2(255),
    PRODUCT_CATEGORY_ENGLISH     VARCHAR2(255),

    PRODUCT_NAME_LENGTH          NUMBER,
    PRODUCT_DESCRIPTION_LENGTH   NUMBER,
    PRODUCT_PHOTOS_QTY           NUMBER,

    PRODUCT_WEIGHT_G             NUMBER,
    PRODUCT_LENGTH_CM            NUMBER,
    PRODUCT_HEIGHT_CM            NUMBER,
    PRODUCT_WIDTH_CM             NUMBER,

    CONSTRAINT PK_GOLD_DIM_PRODUCT
        PRIMARY KEY (PRODUCT_KEY),

    CONSTRAINT UK_GOLD_DIM_PRODUCT_ID
        UNIQUE (PRODUCT_ID)
);


-- ============================================================
-- 5. DIM_SELLER
--
-- Grain :
-- 1 ligne = 1 SELLER_ID
-- ============================================================

CREATE TABLE GOLD.DIM_SELLER (

    SELLER_KEY               NUMBER          NOT NULL,

    SELLER_ID                VARCHAR2(50)    NOT NULL,

    SELLER_ZIP_CODE_PREFIX   NUMBER,

    SELLER_CITY              VARCHAR2(255),
    SELLER_STATE             VARCHAR2(10),

    GEOGRAPHY_KEY            NUMBER          NOT NULL,

    CONSTRAINT PK_GOLD_DIM_SELLER
        PRIMARY KEY (SELLER_KEY),

    CONSTRAINT UK_GOLD_DIM_SELLER_ID
        UNIQUE (SELLER_ID),

    CONSTRAINT FK_SELLER_GEOGRAPHY
        FOREIGN KEY (GEOGRAPHY_KEY)
        REFERENCES GOLD.DIM_GEOGRAPHY (GEOGRAPHY_KEY)
);


-- ============================================================
-- 6. FACT_ORDERS
--
-- Grain :
-- 1 ligne = 1 ORDER_ID
-- ============================================================

CREATE TABLE GOLD.FACT_ORDERS (

    ORDER_ID                         VARCHAR2(50)    NOT NULL,

    CUSTOMER_KEY                     NUMBER          NOT NULL,
    PURCHASE_DATE_KEY                NUMBER(8)       NOT NULL,

    ORDER_STATUS                     VARCHAR2(50),

    ORDER_PURCHASE_TIMESTAMP         TIMESTAMP       NOT NULL,
    ORDER_APPROVED_AT                TIMESTAMP,

    ORDER_DELIVERED_CARRIER_DATE     TIMESTAMP,
    ORDER_DELIVERED_CUSTOMER_DATE    TIMESTAMP,

    ORDER_ESTIMATED_DELIVERY_DATE    TIMESTAMP,

    DELIVERY_DAYS                    NUMBER,
    DELIVERY_DELAY_DAYS              NUMBER,

    IS_LATE_DELIVERY                 NUMBER(1),

    CONSTRAINT PK_GOLD_FACT_ORDERS
        PRIMARY KEY (ORDER_ID),

    CONSTRAINT FK_ORDERS_CUSTOMER
        FOREIGN KEY (CUSTOMER_KEY)
        REFERENCES GOLD.DIM_CUSTOMER (CUSTOMER_KEY),

    CONSTRAINT FK_ORDERS_DATE
        FOREIGN KEY (PURCHASE_DATE_KEY)
        REFERENCES GOLD.DIM_DATE (DATE_KEY),

    CONSTRAINT CK_GOLD_LATE_DELIVERY
        CHECK (
            IS_LATE_DELIVERY IN (0, 1)
            OR IS_LATE_DELIVERY IS NULL
        )
);


-- ============================================================
-- 7. FACT_ORDER_ITEMS
--
-- Grain :
-- 1 ligne = 1 couple
-- (ORDER_ID, ORDER_ITEM_ID)
--
-- Fait commercial principal.
-- ============================================================

CREATE TABLE GOLD.FACT_ORDER_ITEMS (

    ORDER_ID              VARCHAR2(50)    NOT NULL,
    ORDER_ITEM_ID         NUMBER          NOT NULL,

    CUSTOMER_KEY          NUMBER          NOT NULL,
    PRODUCT_KEY           NUMBER          NOT NULL,
    SELLER_KEY            NUMBER          NOT NULL,
    PURCHASE_DATE_KEY     NUMBER(8)       NOT NULL,

    PRICE                  NUMBER(15,2)    NOT NULL,
    FREIGHT_VALUE          NUMBER(15,2)    NOT NULL,

    TOTAL_ITEM_VALUE       NUMBER(15,2)    NOT NULL,

    CONSTRAINT PK_GOLD_FACT_ORDER_ITEMS
        PRIMARY KEY (
            ORDER_ID,
            ORDER_ITEM_ID
        ),

    CONSTRAINT FK_ITEMS_ORDER
        FOREIGN KEY (ORDER_ID)
        REFERENCES GOLD.FACT_ORDERS (ORDER_ID),

    CONSTRAINT FK_ITEMS_CUSTOMER
        FOREIGN KEY (CUSTOMER_KEY)
        REFERENCES GOLD.DIM_CUSTOMER (CUSTOMER_KEY),

    CONSTRAINT FK_ITEMS_PRODUCT
        FOREIGN KEY (PRODUCT_KEY)
        REFERENCES GOLD.DIM_PRODUCT (PRODUCT_KEY),

    CONSTRAINT FK_ITEMS_SELLER
        FOREIGN KEY (SELLER_KEY)
        REFERENCES GOLD.DIM_SELLER (SELLER_KEY),

    CONSTRAINT FK_ITEMS_DATE
        FOREIGN KEY (PURCHASE_DATE_KEY)
        REFERENCES GOLD.DIM_DATE (DATE_KEY),

    CONSTRAINT CK_GOLD_ITEM_PRICE
        CHECK (PRICE > 0),

    CONSTRAINT CK_GOLD_ITEM_FREIGHT
        CHECK (FREIGHT_VALUE >= 0)
);


-- ============================================================
-- 8. FACT_PAYMENTS
--
-- Grain :
-- 1 ligne = 1 couple
-- (ORDER_ID, PAYMENT_SEQUENTIAL)
-- ============================================================

CREATE TABLE GOLD.FACT_PAYMENTS (

    ORDER_ID                VARCHAR2(50)    NOT NULL,
    PAYMENT_SEQUENTIAL      NUMBER          NOT NULL,

    CUSTOMER_KEY            NUMBER          NOT NULL,
    PURCHASE_DATE_KEY       NUMBER(8)       NOT NULL,

    PAYMENT_TYPE            VARCHAR2(50),

    PAYMENT_INSTALLMENTS    NUMBER,

    PAYMENT_VALUE           NUMBER(15,2)    NOT NULL,

    CONSTRAINT PK_GOLD_FACT_PAYMENTS
        PRIMARY KEY (
            ORDER_ID,
            PAYMENT_SEQUENTIAL
        ),

    CONSTRAINT FK_PAYMENTS_ORDER
        FOREIGN KEY (ORDER_ID)
        REFERENCES GOLD.FACT_ORDERS (ORDER_ID),

    CONSTRAINT FK_PAYMENTS_CUSTOMER
        FOREIGN KEY (CUSTOMER_KEY)
        REFERENCES GOLD.DIM_CUSTOMER (CUSTOMER_KEY),

    CONSTRAINT FK_PAYMENTS_DATE
        FOREIGN KEY (PURCHASE_DATE_KEY)
        REFERENCES GOLD.DIM_DATE (DATE_KEY),

    CONSTRAINT CK_GOLD_PAYMENT_VALUE
        CHECK (PAYMENT_VALUE >= 0),

    CONSTRAINT CK_GOLD_PAYMENT_INSTALLMENTS
        CHECK (PAYMENT_INSTALLMENTS >= 0)
);


-- ============================================================
-- 9. FACT_REVIEWS
--
-- Grain :
-- 1 ligne = 1 couple
-- (REVIEW_ID, ORDER_ID)
--
-- Notre analyse SILVER a montre que REVIEW_ID seul
-- n'est pas unique.
-- ============================================================

CREATE TABLE GOLD.FACT_REVIEWS (

    REVIEW_ID            VARCHAR2(50)    NOT NULL,
    ORDER_ID             VARCHAR2(50)    NOT NULL,

    CUSTOMER_KEY         NUMBER          NOT NULL,

    REVIEW_DATE_KEY      NUMBER(8)       NOT NULL,

    REVIEW_SCORE         NUMBER          NOT NULL,

    CONSTRAINT PK_GOLD_FACT_REVIEWS
        PRIMARY KEY (
            REVIEW_ID,
            ORDER_ID
        ),

    CONSTRAINT FK_REVIEWS_ORDER
        FOREIGN KEY (ORDER_ID)
        REFERENCES GOLD.FACT_ORDERS (ORDER_ID),

    CONSTRAINT FK_REVIEWS_CUSTOMER
        FOREIGN KEY (CUSTOMER_KEY)
        REFERENCES GOLD.DIM_CUSTOMER (CUSTOMER_KEY),

    CONSTRAINT FK_REVIEWS_DATE
        FOREIGN KEY (REVIEW_DATE_KEY)
        REFERENCES GOLD.DIM_DATE (DATE_KEY),

    CONSTRAINT CK_GOLD_REVIEW_SCORE
        CHECK (REVIEW_SCORE BETWEEN 1 AND 5)
);


-- ============================================================
-- 10. VERIFICATION DES TABLES GOLD
-- ============================================================

SELECT
    TABLE_NAME
FROM ALL_TABLES
WHERE OWNER = 'GOLD'
ORDER BY TABLE_NAME;


-- ============================================================
-- 11. VERIFICATION DES VOLUMES
--
-- Toutes les tables doivent etre vides.
-- ============================================================

SELECT
    'DIM_DATE' AS TABLE_NAME,
    COUNT(*) AS NB_LIGNES
FROM GOLD.DIM_DATE

UNION ALL

SELECT 'DIM_GEOGRAPHY', COUNT(*)
FROM GOLD.DIM_GEOGRAPHY

UNION ALL

SELECT 'DIM_CUSTOMER', COUNT(*)
FROM GOLD.DIM_CUSTOMER

UNION ALL

SELECT 'DIM_PRODUCT', COUNT(*)
FROM GOLD.DIM_PRODUCT

UNION ALL

SELECT 'DIM_SELLER', COUNT(*)
FROM GOLD.DIM_SELLER

UNION ALL

SELECT 'FACT_ORDERS', COUNT(*)
FROM GOLD.FACT_ORDERS

UNION ALL

SELECT 'FACT_ORDER_ITEMS', COUNT(*)
FROM GOLD.FACT_ORDER_ITEMS

UNION ALL

SELECT 'FACT_PAYMENTS', COUNT(*)
FROM GOLD.FACT_PAYMENTS

UNION ALL

SELECT 'FACT_REVIEWS', COUNT(*)
FROM GOLD.FACT_REVIEWS

ORDER BY TABLE_NAME;


-- ============================================================
-- 12. VERIFICATION DES CONTRAINTES
-- ============================================================

SELECT
    TABLE_NAME,
    CONSTRAINT_NAME,
    CONSTRAINT_TYPE,
    STATUS
FROM ALL_CONSTRAINTS
WHERE OWNER = 'GOLD'
  AND TABLE_NAME IN (
      'DIM_DATE',
      'DIM_GEOGRAPHY',
      'DIM_CUSTOMER',
      'DIM_PRODUCT',
      'DIM_SELLER',
      'FACT_ORDERS',
      'FACT_ORDER_ITEMS',
      'FACT_PAYMENTS',
      'FACT_REVIEWS'
  )
ORDER BY
    TABLE_NAME,
    CONSTRAINT_TYPE,
    CONSTRAINT_NAME;