-- ============================================================
-- MODERN DATA PLATFORM - OLIST
-- ETAPE 3.1
-- CREATION DES TABLES BRONZE
-- ============================================================

ALTER SESSION SET CURRENT_SCHEMA = BRONZE;


-- ============================================================
-- 1. CUSTOMERS
-- Source : olist_customers_dataset.csv
-- ============================================================

CREATE TABLE CUSTOMERS_RAW (
    CUSTOMER_ID                 VARCHAR2(50),
    CUSTOMER_UNIQUE_ID          VARCHAR2(50),
    CUSTOMER_ZIP_CODE_PREFIX    NUMBER,
    CUSTOMER_CITY               VARCHAR2(255),
    CUSTOMER_STATE              VARCHAR2(10),

    BATCH_ID                    VARCHAR2(100) NOT NULL,
    BATCH_DATE                  DATE NOT NULL,
    LOADED_AT                   TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    SOURCE_FILE                 VARCHAR2(255) NOT NULL
);


-- ============================================================
-- 2. GEOLOCATION
-- Source : olist_geolocation_dataset.csv
-- ============================================================

CREATE TABLE GEOLOCATION_RAW (
    GEOLOCATION_ZIP_CODE_PREFIX NUMBER,
    GEOLOCATION_LAT             NUMBER,
    GEOLOCATION_LNG             NUMBER,
    GEOLOCATION_CITY            VARCHAR2(255),
    GEOLOCATION_STATE           VARCHAR2(10),

    BATCH_ID                    VARCHAR2(100) NOT NULL,
    BATCH_DATE                  DATE NOT NULL,
    LOADED_AT                   TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    SOURCE_FILE                 VARCHAR2(255) NOT NULL
);


-- ============================================================
-- 3. ORDER ITEMS
-- Source : olist_order_items_dataset.csv
-- ============================================================

CREATE TABLE ORDER_ITEMS_RAW (
    ORDER_ID                    VARCHAR2(50),
    ORDER_ITEM_ID               NUMBER,
    PRODUCT_ID                  VARCHAR2(50),
    SELLER_ID                   VARCHAR2(50),

    SHIPPING_LIMIT_DATE         VARCHAR2(30),

    PRICE                       NUMBER(15,2),
    FREIGHT_VALUE               NUMBER(15,2),

    BATCH_ID                    VARCHAR2(100) NOT NULL,
    BATCH_DATE                  DATE NOT NULL,
    LOADED_AT                   TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    SOURCE_FILE                 VARCHAR2(255) NOT NULL
);


-- ============================================================
-- 4. PAYMENTS
-- Source : olist_order_payments_dataset.csv
-- ============================================================

CREATE TABLE PAYMENTS_RAW (
    ORDER_ID                    VARCHAR2(50),
    PAYMENT_SEQUENTIAL          NUMBER,
    PAYMENT_TYPE                VARCHAR2(50),
    PAYMENT_INSTALLMENTS        NUMBER,
    PAYMENT_VALUE               NUMBER(15,2),

    BATCH_ID                    VARCHAR2(100) NOT NULL,
    BATCH_DATE                  DATE NOT NULL,
    LOADED_AT                   TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    SOURCE_FILE                 VARCHAR2(255) NOT NULL
);


-- ============================================================
-- 5. REVIEWS
-- Source : olist_order_reviews_dataset.csv
-- ============================================================

CREATE TABLE REVIEWS_RAW (
    REVIEW_ID                   VARCHAR2(50),
    ORDER_ID                    VARCHAR2(50),
    REVIEW_SCORE                NUMBER,

    REVIEW_COMMENT_TITLE        VARCHAR2(1000),
    REVIEW_COMMENT_MESSAGE      CLOB,

    REVIEW_CREATION_DATE        VARCHAR2(30),
    REVIEW_ANSWER_TIMESTAMP     VARCHAR2(30),

    BATCH_ID                    VARCHAR2(100) NOT NULL,
    BATCH_DATE                  DATE NOT NULL,
    LOADED_AT                   TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    SOURCE_FILE                 VARCHAR2(255) NOT NULL
);


-- ============================================================
-- 6. ORDERS
-- Source : olist_orders_dataset.csv
-- ============================================================

CREATE TABLE ORDERS_RAW (
    ORDER_ID                        VARCHAR2(50),
    CUSTOMER_ID                     VARCHAR2(50),
    ORDER_STATUS                    VARCHAR2(50),

    ORDER_PURCHASE_TIMESTAMP        VARCHAR2(30),
    ORDER_APPROVED_AT               VARCHAR2(30),
    ORDER_DELIVERED_CARRIER_DATE    VARCHAR2(30),
    ORDER_DELIVERED_CUSTOMER_DATE   VARCHAR2(30),
    ORDER_ESTIMATED_DELIVERY_DATE   VARCHAR2(30),

    BATCH_ID                        VARCHAR2(100) NOT NULL,
    BATCH_DATE                      DATE NOT NULL,
    LOADED_AT                       TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    SOURCE_FILE                     VARCHAR2(255) NOT NULL
);


-- ============================================================
-- 7. PRODUCTS
-- Source : olist_products_dataset.csv
--
-- On garde volontairement les noms source contenant "LENGHT".
-- Le renommage propre se fera en SILVER.
-- ============================================================

CREATE TABLE PRODUCTS_RAW (
    PRODUCT_ID                      VARCHAR2(50),
    PRODUCT_CATEGORY_NAME           VARCHAR2(255),

    PRODUCT_NAME_LENGHT             NUMBER,
    PRODUCT_DESCRIPTION_LENGHT      NUMBER,
    PRODUCT_PHOTOS_QTY              NUMBER,

    PRODUCT_WEIGHT_G                NUMBER,
    PRODUCT_LENGTH_CM               NUMBER,
    PRODUCT_HEIGHT_CM               NUMBER,
    PRODUCT_WIDTH_CM                NUMBER,

    BATCH_ID                        VARCHAR2(100) NOT NULL,
    BATCH_DATE                      DATE NOT NULL,
    LOADED_AT                       TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    SOURCE_FILE                     VARCHAR2(255) NOT NULL
);


-- ============================================================
-- 8. SELLERS
-- Source : olist_sellers_dataset.csv
-- ============================================================

CREATE TABLE SELLERS_RAW (
    SELLER_ID                   VARCHAR2(50),
    SELLER_ZIP_CODE_PREFIX      NUMBER,
    SELLER_CITY                 VARCHAR2(255),
    SELLER_STATE                VARCHAR2(10),

    BATCH_ID                    VARCHAR2(100) NOT NULL,
    BATCH_DATE                  DATE NOT NULL,
    LOADED_AT                   TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    SOURCE_FILE                 VARCHAR2(255) NOT NULL
);


-- ============================================================
-- 9. PRODUCT CATEGORY TRANSLATION
-- Source : product_category_name_translation.csv
-- ============================================================

CREATE TABLE CATEGORY_TRANSLATION_RAW (
    PRODUCT_CATEGORY_NAME           VARCHAR2(255),
    PRODUCT_CATEGORY_NAME_ENGLISH   VARCHAR2(255),

    BATCH_ID                        VARCHAR2(100) NOT NULL,
    BATCH_DATE                      DATE NOT NULL,
    LOADED_AT                       TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    SOURCE_FILE                     VARCHAR2(255) NOT NULL
);


-- ============================================================
-- VERIFICATION
-- ============================================================

SELECT
    TABLE_NAME
FROM USER_TABLES
WHERE TABLE_NAME LIKE '%RAW'
ORDER BY TABLE_NAME;