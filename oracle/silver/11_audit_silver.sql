-- ============================================================
-- MODERN DATA PLATFORM - OLIST
-- ETAPE 4.12
-- AUDIT GLOBAL DE LA COUCHE SILVER
--
-- Ce script ne modifie aucune donnée.
-- Il vérifie :
-- 1. les volumes
-- 2. les rejets
-- 3. les doublons
-- 4. les relations entre tables
-- 5. la couverture géographique
-- 6. les règles qualité après nettoyage
-- ============================================================


-- ============================================================
-- 1. VOLUMES DES TABLES SILVER
-- ============================================================

SELECT 'CUSTOMERS' AS TABLE_NAME, COUNT(*) AS NB_LIGNES
FROM SILVER.CUSTOMERS

UNION ALL

SELECT 'GEOLOCATION', COUNT(*)
FROM SILVER.GEOLOCATION

UNION ALL

SELECT 'ORDER_ITEMS', COUNT(*)
FROM SILVER.ORDER_ITEMS

UNION ALL

SELECT 'ORDERS', COUNT(*)
FROM SILVER.ORDERS

UNION ALL

SELECT 'PAYMENTS', COUNT(*)
FROM SILVER.PAYMENTS

UNION ALL

SELECT 'PRODUCTS', COUNT(*)
FROM SILVER.PRODUCTS

UNION ALL

SELECT 'REVIEWS', COUNT(*)
FROM SILVER.REVIEWS

UNION ALL

SELECT 'SELLERS', COUNT(*)
FROM SILVER.SELLERS

UNION ALL

SELECT 'CATEGORY_TRANSLATION', COUNT(*)
FROM SILVER.CATEGORY_TRANSLATION

ORDER BY TABLE_NAME;


-- ============================================================
-- 2. TOTAL DES REJETS
-- ============================================================

SELECT
    COUNT(*) AS TOTAL_REJETS
FROM SILVER.REJECTED_ROWS;


-- ============================================================
-- 3. DETAIL DES REJETS PAR REGLE
-- ============================================================

SELECT
    SOURCE_TABLE,
    RULE_CODE,
    COUNT(*) AS NB_REJETS

FROM SILVER.REJECTED_ROWS

GROUP BY
    SOURCE_TABLE,
    RULE_CODE

ORDER BY
    SOURCE_TABLE,
    RULE_CODE;


-- ============================================================
-- 4. VERIFICATION DES CLES LOGIQUES
--
-- Toutes les valeurs doivent etre 0.
-- ============================================================

SELECT
    'CUSTOMERS' AS TABLE_NAME,
    COUNT(*) AS NB_DOUBLONS
FROM (
    SELECT CUSTOMER_ID
    FROM SILVER.CUSTOMERS
    GROUP BY CUSTOMER_ID
    HAVING COUNT(*) > 1
)

UNION ALL

SELECT
    'ORDERS',
    COUNT(*)
FROM (
    SELECT ORDER_ID
    FROM SILVER.ORDERS
    GROUP BY ORDER_ID
    HAVING COUNT(*) > 1
)

UNION ALL

SELECT
    'PRODUCTS',
    COUNT(*)
FROM (
    SELECT PRODUCT_ID
    FROM SILVER.PRODUCTS
    GROUP BY PRODUCT_ID
    HAVING COUNT(*) > 1
)

UNION ALL

SELECT
    'SELLERS',
    COUNT(*)
FROM (
    SELECT SELLER_ID
    FROM SILVER.SELLERS
    GROUP BY SELLER_ID
    HAVING COUNT(*) > 1
)

UNION ALL

SELECT
    'GEOLOCATION',
    COUNT(*)
FROM (
    SELECT GEOLOCATION_ZIP_CODE_PREFIX
    FROM SILVER.GEOLOCATION
    GROUP BY GEOLOCATION_ZIP_CODE_PREFIX
    HAVING COUNT(*) > 1
)

UNION ALL

SELECT
    'ORDER_ITEMS',
    COUNT(*)
FROM (
    SELECT
        ORDER_ID,
        ORDER_ITEM_ID
    FROM SILVER.ORDER_ITEMS
    GROUP BY
        ORDER_ID,
        ORDER_ITEM_ID
    HAVING COUNT(*) > 1
)

UNION ALL

SELECT
    'PAYMENTS',
    COUNT(*)
FROM (
    SELECT
        ORDER_ID,
        PAYMENT_SEQUENTIAL
    FROM SILVER.PAYMENTS
    GROUP BY
        ORDER_ID,
        PAYMENT_SEQUENTIAL
    HAVING COUNT(*) > 1
)

UNION ALL

SELECT
    'REVIEWS',
    COUNT(*)
FROM (
    SELECT
        REVIEW_ID,
        ORDER_ID
    FROM SILVER.REVIEWS
    GROUP BY
        REVIEW_ID,
        ORDER_ID
    HAVING COUNT(*) > 1
)

UNION ALL

SELECT
    'CATEGORY_TRANSLATION',
    COUNT(*)
FROM (
    SELECT PRODUCT_CATEGORY_NAME
    FROM SILVER.CATEGORY_TRANSLATION
    GROUP BY PRODUCT_CATEGORY_NAME
    HAVING COUNT(*) > 1
)

ORDER BY TABLE_NAME;


-- ============================================================
-- 5. ORDERS SANS CUSTOMER
--
-- Une commande SILVER doit avoir un client SILVER.
-- ============================================================

SELECT
    COUNT(*) AS ORDERS_SANS_CUSTOMER
FROM SILVER.ORDERS O
WHERE NOT EXISTS (
    SELECT 1
    FROM SILVER.CUSTOMERS C
    WHERE C.CUSTOMER_ID = O.CUSTOMER_ID
);


-- ============================================================
-- 6. ORDER_ITEMS SANS ORDER SILVER
--
-- On sait que certaines commandes ont ete rejetees.
-- Cette requete mesure leurs lignes enfants restantes.
-- ============================================================

SELECT
    COUNT(*) AS ITEMS_SANS_ORDER_SILVER
FROM SILVER.ORDER_ITEMS I
WHERE NOT EXISTS (
    SELECT 1
    FROM SILVER.ORDERS O
    WHERE O.ORDER_ID = I.ORDER_ID
);


-- ============================================================
-- 7. ORDER_ITEMS SANS PRODUCT SILVER
--
-- Certains produits ont ete rejetes avec PRD_001.
-- ============================================================

SELECT
    COUNT(*) AS ITEMS_SANS_PRODUCT_SILVER
FROM SILVER.ORDER_ITEMS I
WHERE NOT EXISTS (
    SELECT 1
    FROM SILVER.PRODUCTS P
    WHERE P.PRODUCT_ID = I.PRODUCT_ID
);


-- ============================================================
-- 8. ORDER_ITEMS SANS SELLER SILVER
-- ============================================================

SELECT
    COUNT(*) AS ITEMS_SANS_SELLER_SILVER
FROM SILVER.ORDER_ITEMS I
WHERE NOT EXISTS (
    SELECT 1
    FROM SILVER.SELLERS S
    WHERE S.SELLER_ID = I.SELLER_ID
);


-- ============================================================
-- 9. PAYMENTS SANS ORDER SILVER
-- ============================================================

SELECT
    COUNT(*) AS PAYMENTS_SANS_ORDER_SILVER
FROM SILVER.PAYMENTS P
WHERE NOT EXISTS (
    SELECT 1
    FROM SILVER.ORDERS O
    WHERE O.ORDER_ID = P.ORDER_ID
);


-- ============================================================
-- 10. REVIEWS SANS ORDER SILVER
-- ============================================================

SELECT
    COUNT(*) AS REVIEWS_SANS_ORDER_SILVER
FROM SILVER.REVIEWS R
WHERE NOT EXISTS (
    SELECT 1
    FROM SILVER.ORDERS O
    WHERE O.ORDER_ID = R.ORDER_ID
);


-- ============================================================
-- 11. CODES POSTAUX CLIENTS SANS GEOLOCATION
--
-- Il s'agit d'une alerte de couverture.
-- Les clients ne sont pas rejetes.
-- ============================================================

SELECT
    COUNT(
        DISTINCT C.CUSTOMER_ZIP_CODE_PREFIX
    ) AS ZIP_CLIENTS_SANS_GEO

FROM SILVER.CUSTOMERS C

WHERE NOT EXISTS (
    SELECT 1
    FROM SILVER.GEOLOCATION G
    WHERE G.GEOLOCATION_ZIP_CODE_PREFIX =
          C.CUSTOMER_ZIP_CODE_PREFIX
);


-- ============================================================
-- 12. CODES POSTAUX SELLERS SANS GEOLOCATION
-- ============================================================

SELECT
    COUNT(
        DISTINCT S.SELLER_ZIP_CODE_PREFIX
    ) AS ZIP_SELLERS_SANS_GEO

FROM SILVER.SELLERS S

WHERE NOT EXISTS (
    SELECT 1
    FROM SILVER.GEOLOCATION G
    WHERE G.GEOLOCATION_ZIP_CODE_PREFIX =
          S.SELLER_ZIP_CODE_PREFIX
);


-- ============================================================
-- 13. ORDERS :
-- LIVRAISON CLIENT AVANT REMISE AU TRANSPORTEUR
--
-- Doit retourner 0.
-- ============================================================

SELECT
    COUNT(*) AS ORDERS_DATE_INCOHERENTE
FROM SILVER.ORDERS
WHERE
    ORDER_DELIVERED_CUSTOMER_DATE IS NOT NULL
    AND ORDER_DELIVERED_CARRIER_DATE IS NOT NULL
    AND ORDER_DELIVERED_CUSTOMER_DATE
        < ORDER_DELIVERED_CARRIER_DATE;


-- ============================================================
-- 14. ORDERS :
-- DELIVERED SANS DATE DE LIVRAISON
--
-- Doit retourner 0.
-- ============================================================

SELECT
    COUNT(*) AS DELIVERED_SANS_DATE
FROM SILVER.ORDERS
WHERE LOWER(TRIM(ORDER_STATUS)) = 'delivered'
  AND ORDER_DELIVERED_CUSTOMER_DATE IS NULL;


-- ============================================================
-- 15. ORDERS :
-- APPROBATION AVANT ACHAT
--
-- Doit retourner 0.
-- ============================================================

SELECT
    COUNT(*) AS APPROVED_AVANT_PURCHASE
FROM SILVER.ORDERS
WHERE ORDER_APPROVED_AT IS NOT NULL
  AND ORDER_PURCHASE_TIMESTAMP IS NOT NULL
  AND ORDER_APPROVED_AT < ORDER_PURCHASE_TIMESTAMP;


-- ============================================================
-- 16. PRODUCTS :
-- POIDS INVALIDE
--
-- Doit retourner 0.
-- ============================================================

SELECT
    COUNT(*) AS PRODUCTS_POIDS_INVALIDE
FROM SILVER.PRODUCTS
WHERE PRODUCT_WEIGHT_G IS NOT NULL
  AND PRODUCT_WEIGHT_G <= 0;


-- ============================================================
-- 17. ORDER_ITEMS :
-- PRIX INVALIDE
--
-- Doit retourner 0.
-- ============================================================

SELECT
    COUNT(*) AS ITEMS_PRIX_INVALIDE
FROM SILVER.ORDER_ITEMS
WHERE PRICE IS NULL
   OR PRICE <= 0;


-- ============================================================
-- 18. ORDER_ITEMS :
-- FRET INVALIDE
--
-- Doit retourner 0.
-- ============================================================

SELECT
    COUNT(*) AS ITEMS_FRET_INVALIDE
FROM SILVER.ORDER_ITEMS
WHERE FREIGHT_VALUE IS NULL
   OR FREIGHT_VALUE < 0;


-- ============================================================
-- 19. PAYMENTS :
-- MONTANT INVALIDE
--
-- Doit retourner 0.
-- ============================================================

SELECT
    COUNT(*) AS PAYMENTS_MONTANT_INVALIDE
FROM SILVER.PAYMENTS
WHERE PAYMENT_VALUE IS NULL
   OR PAYMENT_VALUE < 0;


-- ============================================================
-- 20. PAYMENTS :
-- NOMBRE DE MENSUALITES INVALIDE
--
-- Doit retourner 0.
-- ============================================================

SELECT
    COUNT(*) AS PAYMENTS_INSTALLMENTS_INVALIDES
FROM SILVER.PAYMENTS
WHERE PAYMENT_INSTALLMENTS IS NULL
   OR PAYMENT_INSTALLMENTS < 0;


-- ============================================================
-- 21. REVIEWS :
-- SCORE HORS INTERVALLE [1,5]
--
-- Doit retourner 0.
-- ============================================================

SELECT
    COUNT(*) AS REVIEWS_SCORE_INVALIDE
FROM SILVER.REVIEWS
WHERE REVIEW_SCORE IS NULL
   OR REVIEW_SCORE < 1
   OR REVIEW_SCORE > 5;


-- ============================================================
-- 22. REVIEWS :
-- VERIFICATION DU GRAIN REVIEW_ID + ORDER_ID
--
-- Doit retourner 0.
-- ============================================================

SELECT
    COUNT(*) AS REVIEW_ORDER_DUPLIQUES
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
-- 23. GEOLOCATION :
-- VERIFICATION DU GRAIN 1 ZIP = 1 LIGNE
--
-- Doit retourner 0.
-- ============================================================

SELECT
    COUNT(*) AS GEO_ZIP_DUPLIQUES
FROM (
    SELECT
        GEOLOCATION_ZIP_CODE_PREFIX
    FROM SILVER.GEOLOCATION
    GROUP BY
        GEOLOCATION_ZIP_CODE_PREFIX
    HAVING COUNT(*) > 1
);


-- ============================================================
-- 24. PRODUCTS :
-- CATEGORIES SANS TRADUCTION
--
-- Information seulement.
-- Ces produits restent valides.
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


-- ============================================================
-- 25. SYNTHESE DES RELATIONS ORPHELINES
--
-- Cette requete regroupe les indicateurs importants avant GOLD.
-- ============================================================

SELECT
    'ITEMS_SANS_ORDER' AS CONTROLE,
    COUNT(*) AS NB_LIGNES
FROM SILVER.ORDER_ITEMS I
WHERE NOT EXISTS (
    SELECT 1
    FROM SILVER.ORDERS O
    WHERE O.ORDER_ID = I.ORDER_ID
)

UNION ALL

SELECT
    'ITEMS_SANS_PRODUCT',
    COUNT(*)
FROM SILVER.ORDER_ITEMS I
WHERE NOT EXISTS (
    SELECT 1
    FROM SILVER.PRODUCTS P
    WHERE P.PRODUCT_ID = I.PRODUCT_ID
)

UNION ALL

SELECT
    'ITEMS_SANS_SELLER',
    COUNT(*)
FROM SILVER.ORDER_ITEMS I
WHERE NOT EXISTS (
    SELECT 1
    FROM SILVER.SELLERS S
    WHERE S.SELLER_ID = I.SELLER_ID
)

UNION ALL

SELECT
    'PAYMENTS_SANS_ORDER',
    COUNT(*)
FROM SILVER.PAYMENTS P
WHERE NOT EXISTS (
    SELECT 1
    FROM SILVER.ORDERS O
    WHERE O.ORDER_ID = P.ORDER_ID
)

UNION ALL

SELECT
    'REVIEWS_SANS_ORDER',
    COUNT(*)
FROM SILVER.REVIEWS R
WHERE NOT EXISTS (
    SELECT 1
    FROM SILVER.ORDERS O
    WHERE O.ORDER_ID = R.ORDER_ID
)

ORDER BY CONTROLE;