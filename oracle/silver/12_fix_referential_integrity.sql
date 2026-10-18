-- ============================================================
-- MODERN DATA PLATFORM - OLIST
-- ETAPE 4.13
-- CORRECTION DE LA COHERENCE REFERENTIELLE SILVER
--
-- Objectif :
-- - identifier les enfants dont le parent a ete rejete
-- - enregistrer les anomalies dans REJECTED_ROWS
-- - supprimer les lignes orphelines de SILVER
-- - conserver BRONZE intact
--
-- Tables concernees :
-- - SILVER.ORDER_ITEMS
-- - SILVER.PAYMENTS
-- - SILVER.REVIEWS
-- ============================================================


-- ============================================================
-- 0. NETTOYAGE DES ANCIENS REJETS REFERENTIELS
--
-- Les donnees BRONZE sont conservees.
-- Les rejets pourront donc etre recrees a chaque execution.
-- ============================================================

DELETE FROM SILVER.REJECTED_ROWS
WHERE RULE_CODE IN (
    'REF_ITEM_ORDER',
    'REF_ITEM_PRODUCT',
    'REF_ITEM_SELLER',
    'REF_PAY_ORDER',
    'REF_REV_ORDER'
);

COMMIT;


-- ============================================================
-- 1. ORDER_ITEMS DONT LA COMMANDE N'EXISTE PLUS
--
-- Cas detecte par l'audit :
-- 58 lignes avant correction.
-- ============================================================

INSERT INTO SILVER.REJECTED_ROWS (
    REJECT_ID,
    SOURCE_TABLE,
    SOURCE_KEY,
    SOURCE_BATCH_ID,
    RULE_CODE,
    RULE_DESCRIPTION,
    REJECT_REASON,
    RAW_DATA
)
SELECT
    'REFITEMORDER-'
        || I.ORDER_ID
        || '-'
        || I.ORDER_ITEM_ID,

    'ORDER_ITEMS_RAW',

    I.ORDER_ID
        || '-'
        || I.ORDER_ITEM_ID,

    I.BATCH_ID,

    'REF_ITEM_ORDER',

    'Article rattache a une commande absente de SILVER.ORDERS',

    'Le parent ORDER_ID a ete rejete ou ne peut pas etre retrouve dans SILVER.ORDERS',

    'order_id='
        || I.ORDER_ID
        || '; order_item_id='
        || TO_CHAR(I.ORDER_ITEM_ID)
        || '; product_id='
        || NVL(I.PRODUCT_ID, 'NULL')
        || '; seller_id='
        || NVL(I.SELLER_ID, 'NULL')
        || '; price='
        || NVL(TO_CHAR(I.PRICE), 'NULL')
        || '; freight_value='
        || NVL(TO_CHAR(I.FREIGHT_VALUE), 'NULL')

FROM BRONZE.ORDER_ITEMS_RAW I

WHERE NOT EXISTS (
    SELECT 1
    FROM SILVER.ORDERS O
    WHERE O.ORDER_ID = I.ORDER_ID
);


-- ============================================================
-- 2. ORDER_ITEMS DONT LE PRODUIT N'EXISTE PLUS
--
-- Cas detecte par l'audit :
-- 8 lignes avant correction.
-- ============================================================

INSERT INTO SILVER.REJECTED_ROWS (
    REJECT_ID,
    SOURCE_TABLE,
    SOURCE_KEY,
    SOURCE_BATCH_ID,
    RULE_CODE,
    RULE_DESCRIPTION,
    REJECT_REASON,
    RAW_DATA
)
SELECT
    'REFITEMPRODUCT-'
        || I.ORDER_ID
        || '-'
        || I.ORDER_ITEM_ID,

    'ORDER_ITEMS_RAW',

    I.ORDER_ID
        || '-'
        || I.ORDER_ITEM_ID,

    I.BATCH_ID,

    'REF_ITEM_PRODUCT',

    'Article rattache a un produit absent de SILVER.PRODUCTS',

    'Le parent PRODUCT_ID a ete rejete ou ne peut pas etre retrouve dans SILVER.PRODUCTS',

    'order_id='
        || I.ORDER_ID
        || '; order_item_id='
        || TO_CHAR(I.ORDER_ITEM_ID)
        || '; product_id='
        || NVL(I.PRODUCT_ID, 'NULL')
        || '; seller_id='
        || NVL(I.SELLER_ID, 'NULL')
        || '; price='
        || NVL(TO_CHAR(I.PRICE), 'NULL')

FROM BRONZE.ORDER_ITEMS_RAW I

WHERE NOT EXISTS (
    SELECT 1
    FROM SILVER.PRODUCTS P
    WHERE P.PRODUCT_ID = I.PRODUCT_ID
);


-- ============================================================
-- 3. ORDER_ITEMS DONT LE SELLER N'EXISTE PLUS
--
-- L'audit avait retourne 0.
-- La regle est tout de meme incluse pour rendre le controle
-- complet et reutilisable.
-- ============================================================

INSERT INTO SILVER.REJECTED_ROWS (
    REJECT_ID,
    SOURCE_TABLE,
    SOURCE_KEY,
    SOURCE_BATCH_ID,
    RULE_CODE,
    RULE_DESCRIPTION,
    REJECT_REASON,
    RAW_DATA
)
SELECT
    'REFITEMSELLER-'
        || I.ORDER_ID
        || '-'
        || I.ORDER_ITEM_ID,

    'ORDER_ITEMS_RAW',

    I.ORDER_ID
        || '-'
        || I.ORDER_ITEM_ID,

    I.BATCH_ID,

    'REF_ITEM_SELLER',

    'Article rattache a un vendeur absent de SILVER.SELLERS',

    'Le parent SELLER_ID ne peut pas etre retrouve dans SILVER.SELLERS',

    'order_id='
        || I.ORDER_ID
        || '; order_item_id='
        || TO_CHAR(I.ORDER_ITEM_ID)
        || '; seller_id='
        || NVL(I.SELLER_ID, 'NULL')
        || '; product_id='
        || NVL(I.PRODUCT_ID, 'NULL')

FROM BRONZE.ORDER_ITEMS_RAW I

WHERE NOT EXISTS (
    SELECT 1
    FROM SILVER.SELLERS S
    WHERE S.SELLER_ID = I.SELLER_ID
);


-- ============================================================
-- 4. PAYMENTS DONT LA COMMANDE N'EXISTE PLUS
--
-- Cas detecte par l'audit :
-- 34 lignes avant correction.
-- ============================================================

INSERT INTO SILVER.REJECTED_ROWS (
    REJECT_ID,
    SOURCE_TABLE,
    SOURCE_KEY,
    SOURCE_BATCH_ID,
    RULE_CODE,
    RULE_DESCRIPTION,
    REJECT_REASON,
    RAW_DATA
)
SELECT
    'REFPAYORDER-'
        || P.ORDER_ID
        || '-'
        || P.PAYMENT_SEQUENTIAL,

    'PAYMENTS_RAW',

    P.ORDER_ID
        || '-'
        || P.PAYMENT_SEQUENTIAL,

    P.BATCH_ID,

    'REF_PAY_ORDER',

    'Paiement rattache a une commande absente de SILVER.ORDERS',

    'Le parent ORDER_ID a ete rejete ou ne peut pas etre retrouve dans SILVER.ORDERS',

    'order_id='
        || P.ORDER_ID
        || '; payment_sequential='
        || TO_CHAR(P.PAYMENT_SEQUENTIAL)
        || '; payment_type='
        || NVL(P.PAYMENT_TYPE, 'NULL')
        || '; payment_installments='
        || NVL(
            TO_CHAR(P.PAYMENT_INSTALLMENTS),
            'NULL'
        )
        || '; payment_value='
        || NVL(
            TO_CHAR(P.PAYMENT_VALUE),
            'NULL'
        )

FROM BRONZE.PAYMENTS_RAW P

WHERE NOT EXISTS (
    SELECT 1
    FROM SILVER.ORDERS O
    WHERE O.ORDER_ID = P.ORDER_ID
);


-- ============================================================
-- 5. REVIEWS DONT LA COMMANDE N'EXISTE PLUS
--
-- Cas detecte par l'audit :
-- 31 lignes avant correction.
-- ============================================================

INSERT INTO SILVER.REJECTED_ROWS (
    REJECT_ID,
    SOURCE_TABLE,
    SOURCE_KEY,
    SOURCE_BATCH_ID,
    RULE_CODE,
    RULE_DESCRIPTION,
    REJECT_REASON,
    RAW_DATA
)
SELECT
    'REFREVORDER-'
        || R.REVIEW_ID
        || '-'
        || R.ORDER_ID,

    'REVIEWS_RAW',

    R.REVIEW_ID
        || '-'
        || R.ORDER_ID,

    R.BATCH_ID,

    'REF_REV_ORDER',

    'Avis rattache a une commande absente de SILVER.ORDERS',

    'Le parent ORDER_ID a ete rejete ou ne peut pas etre retrouve dans SILVER.ORDERS',

    'review_id='
        || R.REVIEW_ID
        || '; order_id='
        || R.ORDER_ID
        || '; review_score='
        || NVL(
            TO_CHAR(R.REVIEW_SCORE),
            'NULL'
        )
        || '; review_creation_date='
        || NVL(
            R.REVIEW_CREATION_DATE,
            'NULL'
        )

FROM BRONZE.REVIEWS_RAW R

WHERE NOT EXISTS (
    SELECT 1
    FROM SILVER.ORDERS O
    WHERE O.ORDER_ID = R.ORDER_ID
);


COMMIT;


-- ============================================================
-- 6. VERIFICATION DES REJETS REFERENTIELS AVANT SUPPRESSION
-- ============================================================

SELECT
    RULE_CODE,
    COUNT(*) AS NB_REJETS

FROM SILVER.REJECTED_ROWS

WHERE RULE_CODE IN (
    'REF_ITEM_ORDER',
    'REF_ITEM_PRODUCT',
    'REF_ITEM_SELLER',
    'REF_PAY_ORDER',
    'REF_REV_ORDER'
)

GROUP BY RULE_CODE

ORDER BY RULE_CODE;


-- ============================================================
-- 7. SUPPRESSION DES ORDER_ITEMS ORPHELINS
--
-- Une ligne est supprimee si :
-- - sa commande n'existe pas dans SILVER.ORDERS
-- - ou son produit n'existe pas dans SILVER.PRODUCTS
-- - ou son vendeur n'existe pas dans SILVER.SELLERS
--
-- Une ligne qui viole plusieurs relations n'est supprimee
-- qu'une seule fois.
-- ============================================================

DELETE FROM SILVER.ORDER_ITEMS I

WHERE NOT EXISTS (
    SELECT 1
    FROM SILVER.ORDERS O
    WHERE O.ORDER_ID = I.ORDER_ID
)

OR NOT EXISTS (
    SELECT 1
    FROM SILVER.PRODUCTS P
    WHERE P.PRODUCT_ID = I.PRODUCT_ID
)

OR NOT EXISTS (
    SELECT 1
    FROM SILVER.SELLERS S
    WHERE S.SELLER_ID = I.SELLER_ID
);


-- ============================================================
-- 8. SUPPRESSION DES PAYMENTS ORPHELINS
-- ============================================================

DELETE FROM SILVER.PAYMENTS P

WHERE NOT EXISTS (
    SELECT 1
    FROM SILVER.ORDERS O
    WHERE O.ORDER_ID = P.ORDER_ID
);


-- ============================================================
-- 9. SUPPRESSION DES REVIEWS ORPHELINS
-- ============================================================

DELETE FROM SILVER.REVIEWS R

WHERE NOT EXISTS (
    SELECT 1
    FROM SILVER.ORDERS O
    WHERE O.ORDER_ID = R.ORDER_ID
);


COMMIT;


-- ============================================================
-- 10. VOLUMES APRES CORRECTION
-- ============================================================

SELECT
    'ORDER_ITEMS' AS TABLE_NAME,
    COUNT(*) AS NB_LIGNES
FROM SILVER.ORDER_ITEMS

UNION ALL

SELECT
    'PAYMENTS',
    COUNT(*)
FROM SILVER.PAYMENTS

UNION ALL

SELECT
    'REVIEWS',
    COUNT(*)
FROM SILVER.REVIEWS

ORDER BY TABLE_NAME;


-- ============================================================
-- 11. CONTROLE DES ORDER_ITEMS SANS ORDER
-- Doit retourner 0.
-- ============================================================

SELECT
    COUNT(*) AS ITEMS_SANS_ORDER
FROM SILVER.ORDER_ITEMS I

WHERE NOT EXISTS (
    SELECT 1
    FROM SILVER.ORDERS O
    WHERE O.ORDER_ID = I.ORDER_ID
);


-- ============================================================
-- 12. CONTROLE DES ORDER_ITEMS SANS PRODUCT
-- Doit retourner 0.
-- ============================================================

SELECT
    COUNT(*) AS ITEMS_SANS_PRODUCT
FROM SILVER.ORDER_ITEMS I

WHERE NOT EXISTS (
    SELECT 1
    FROM SILVER.PRODUCTS P
    WHERE P.PRODUCT_ID = I.PRODUCT_ID
);


-- ============================================================
-- 13. CONTROLE DES ORDER_ITEMS SANS SELLER
-- Doit retourner 0.
-- ============================================================

SELECT
    COUNT(*) AS ITEMS_SANS_SELLER
FROM SILVER.ORDER_ITEMS I

WHERE NOT EXISTS (
    SELECT 1
    FROM SILVER.SELLERS S
    WHERE S.SELLER_ID = I.SELLER_ID
);


-- ============================================================
-- 14. CONTROLE DES PAYMENTS SANS ORDER
-- Doit retourner 0.
-- ============================================================

SELECT
    COUNT(*) AS PAYMENTS_SANS_ORDER
FROM SILVER.PAYMENTS P

WHERE NOT EXISTS (
    SELECT 1
    FROM SILVER.ORDERS O
    WHERE O.ORDER_ID = P.ORDER_ID
);


-- ============================================================
-- 15. CONTROLE DES REVIEWS SANS ORDER
-- Doit retourner 0.
-- ============================================================

SELECT
    COUNT(*) AS REVIEWS_SANS_ORDER
FROM SILVER.REVIEWS R

WHERE NOT EXISTS (
    SELECT 1
    FROM SILVER.ORDERS O
    WHERE O.ORDER_ID = R.ORDER_ID
);


-- ============================================================
-- 16. TOTAL GLOBAL DES REJETS
--
-- Le total ne correspond pas obligatoirement au nombre de
-- lignes supprimees :
-- un même ORDER_ITEM peut violer plusieurs regles et produire
-- plusieurs motifs de rejet.
-- ============================================================

SELECT
    COUNT(*) AS TOTAL_REJETS_APRES_CORRECTION
FROM SILVER.REJECTED_ROWS;


-- ============================================================
-- 17. DETAIL GLOBAL DES REJETS
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
-- 18. SYNTHESE FINALE DES RELATIONS
--
-- Toutes les valeurs doivent etre 0.
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