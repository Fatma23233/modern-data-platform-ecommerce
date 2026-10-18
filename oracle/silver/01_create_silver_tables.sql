-- ============================================================
-- MODERN DATA PLATFORM - OLIST
-- ETAPE 4.1
-- CREATION DES TABLES SILVER
-- ============================================================

ALTER SESSION SET CURRENT_SCHEMA = SILVER;


-- ============================================================
-- 1. CUSTOMERS
-- ============================================================

CREATE TABLE CUSTOMERS (
    CUSTOMER_ID                 VARCHAR2(50) PRIMARY KEY,
    CUSTOMER_UNIQUE_ID          VARCHAR2(50) NOT NULL,
    CUSTOMER_ZIP_CODE_PREFIX    NUMBER,
    CUSTOMER_CITY               VARCHAR2(255),
    CUSTOMER_STATE              VARCHAR2(10),

    SOURCE_BATCH_ID             VARCHAR2(100),
    SILVER_LOADED_AT            TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL
);


-- ============================================================
-- 2. GEOLOCATION
--
-- Pas de PRIMARY KEY sur ZIP_CODE :
-- le même préfixe peut apparaître plusieurs fois dans la source.
-- La transformation décidera de la stratégie de consolidation.
-- ============================================================

CREATE TABLE GEOLOCATION (
    GEOLOCATION_ZIP_CODE_PREFIX NUMBER,
    GEOLOCATION_LAT             NUMBER,
    GEOLOCATION_LNG             NUMBER,
    GEOLOCATION_CITY            VARCHAR2(255),
    GEOLOCATION_STATE           VARCHAR2(10),

    SOURCE_BATCH_ID             VARCHAR2(100),
    SILVER_LOADED_AT            TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL
);


-- ============================================================
-- 3. PRODUCTS
-- ============================================================

CREATE TABLE PRODUCTS (
    PRODUCT_ID                  VARCHAR2(50) PRIMARY KEY,

    PRODUCT_CATEGORY_NAME       VARCHAR2(255),
    PRODUCT_CATEGORY_ENGLISH    VARCHAR2(255),

    PRODUCT_NAME_LENGTH         NUMBER,
    PRODUCT_DESCRIPTION_LENGTH  NUMBER,
    PRODUCT_PHOTOS_QTY          NUMBER,

    PRODUCT_WEIGHT_G            NUMBER,
    PRODUCT_LENGTH_CM           NUMBER,
    PRODUCT_HEIGHT_CM           NUMBER,
    PRODUCT_WIDTH_CM            NUMBER,

    SOURCE_BATCH_ID             VARCHAR2(100),
    SILVER_LOADED_AT            TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL
);


-- ============================================================
-- 4. SELLERS
-- ============================================================

CREATE TABLE SELLERS (
    SELLER_ID                   VARCHAR2(50) PRIMARY KEY,
    SELLER_ZIP_CODE_PREFIX      NUMBER,
    SELLER_CITY                 VARCHAR2(255),
    SELLER_STATE                VARCHAR2(10),

    SOURCE_BATCH_ID             VARCHAR2(100),
    SILVER_LOADED_AT            TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL
);


-- ============================================================
-- 5. ORDERS
--
-- Les dates VARCHAR2 de BRONZE deviennent TIMESTAMP ici.
-- ============================================================

CREATE TABLE ORDERS (
    ORDER_ID                        VARCHAR2(50) PRIMARY KEY,
    CUSTOMER_ID                     VARCHAR2(50) NOT NULL,
    ORDER_STATUS                    VARCHAR2(50) NOT NULL,

    ORDER_PURCHASE_TIMESTAMP        TIMESTAMP NOT NULL,
    ORDER_APPROVED_AT               TIMESTAMP,
    ORDER_DELIVERED_CARRIER_DATE    TIMESTAMP,
    ORDER_DELIVERED_CUSTOMER_DATE   TIMESTAMP,
    ORDER_ESTIMATED_DELIVERY_DATE   TIMESTAMP,

    SOURCE_BATCH_ID                 VARCHAR2(100),
    SILVER_LOADED_AT                TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL
);


-- ============================================================
-- 6. ORDER ITEMS
-- ============================================================

CREATE TABLE ORDER_ITEMS (
    ORDER_ID                    VARCHAR2(50) NOT NULL,
    ORDER_ITEM_ID               NUMBER NOT NULL,

    PRODUCT_ID                  VARCHAR2(50) NOT NULL,
    SELLER_ID                   VARCHAR2(50) NOT NULL,

    SHIPPING_LIMIT_DATE         TIMESTAMP,

    PRICE                       NUMBER(15,2),
    FREIGHT_VALUE               NUMBER(15,2),

    SOURCE_BATCH_ID             VARCHAR2(100),
    SILVER_LOADED_AT            TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,

    CONSTRAINT PK_SILVER_ORDER_ITEMS
        PRIMARY KEY (
            ORDER_ID,
            ORDER_ITEM_ID
        )
);


-- ============================================================
-- 7. PAYMENTS
-- ============================================================

CREATE TABLE PAYMENTS (
    ORDER_ID                    VARCHAR2(50) NOT NULL,
    PAYMENT_SEQUENTIAL          NUMBER NOT NULL,
    PAYMENT_TYPE                VARCHAR2(50),
    PAYMENT_INSTALLMENTS        NUMBER,
    PAYMENT_VALUE               NUMBER(15,2),

    SOURCE_BATCH_ID             VARCHAR2(100),
    SILVER_LOADED_AT            TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,

    CONSTRAINT PK_SILVER_PAYMENTS
        PRIMARY KEY (
            ORDER_ID,
            PAYMENT_SEQUENTIAL
        )
);


-- ============================================================
-- 8. REVIEWS
--
-- REVIEW_ID n'est volontairement PAS PRIMARY KEY.
-- Nos contrôles ont détecté 789 review_id répétés.
-- La règle de déduplication sera appliquée à l'étape suivante.
-- ============================================================

CREATE TABLE REVIEWS (
    REVIEW_ID                   VARCHAR2(50),
    ORDER_ID                    VARCHAR2(50) NOT NULL,
    REVIEW_SCORE                NUMBER,

    REVIEW_COMMENT_TITLE        VARCHAR2(1000),
    REVIEW_COMMENT_MESSAGE      CLOB,

    REVIEW_CREATION_DATE        TIMESTAMP,
    REVIEW_ANSWER_TIMESTAMP     TIMESTAMP,

    SOURCE_BATCH_ID             VARCHAR2(100),
    SILVER_LOADED_AT            TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL
);


-- ============================================================
-- 9. CATEGORY TRANSLATION
-- ============================================================

CREATE TABLE CATEGORY_TRANSLATION (
    PRODUCT_CATEGORY_NAME           VARCHAR2(255) PRIMARY KEY,
    PRODUCT_CATEGORY_NAME_ENGLISH   VARCHAR2(255) NOT NULL,

    SOURCE_BATCH_ID                 VARCHAR2(100),
    SILVER_LOADED_AT                TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL
);


-- ============================================================
-- 10. REJECTED_ROWS
--
-- Cette table conserve les données qui ne passent pas
-- les règles de qualité SILVER.
-- ============================================================

CREATE TABLE REJECTED_ROWS (
    REJECT_ID              VARCHAR2(100) PRIMARY KEY,

    SOURCE_TABLE           VARCHAR2(128) NOT NULL,
    SOURCE_KEY             VARCHAR2(500),

    SOURCE_BATCH_ID        VARCHAR2(100),

    RULE_CODE              VARCHAR2(100) NOT NULL,
    RULE_DESCRIPTION       VARCHAR2(1000) NOT NULL,

    REJECT_REASON          VARCHAR2(4000) NOT NULL,

    RAW_DATA               CLOB,

    REJECTED_AT            TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL
);


-- ============================================================
-- VERIFICATION DES TABLES
-- ============================================================

SELECT
    TABLE_NAME
FROM USER_TABLES
ORDER BY TABLE_NAME;