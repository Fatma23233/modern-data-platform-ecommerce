from pathlib import Path
from datetime import datetime
import json
import sys

import pandas as pd


# ============================================================
# CONFIGURATION
# ============================================================

PROJECT_ROOT = Path(__file__).resolve().parents[1]
RAW_DIR = PROJECT_ROOT / "data" / "raw"
REPORT_DIR = PROJECT_ROOT / "data" / "reports"

FILES = {
    "customers": "olist_customers_dataset.csv",
    "geolocation": "olist_geolocation_dataset.csv",
    "order_items": "olist_order_items_dataset.csv",
    "payments": "olist_order_payments_dataset.csv",
    "reviews": "olist_order_reviews_dataset.csv",
    "orders": "olist_orders_dataset.csv",
    "products": "olist_products_dataset.csv",
    "sellers": "olist_sellers_dataset.csv",
    "translations": "product_category_name_translation.csv",
}


# ============================================================
# AFFICHAGE
# ============================================================

def separator(title=""):
    print("\n" + "=" * 100)

    if title:
        print(title)
        print("=" * 100)


def status_label(count, critical=True):
    if count == 0:
        return "OK"

    if critical:
        return "ERREUR"

    return "ATTENTION"


def print_result(label, count, critical=True):
    status = status_label(count, critical)

    print(
        f"[{status:<9}] "
        f"{label:<70} "
        f"{count:>12,}"
    )


# ============================================================
# CHARGEMENT DES CSV
# ============================================================

def load_csv(path):
    try:
        return pd.read_csv(
            path,
            low_memory=False
        )

    except UnicodeDecodeError:
        return pd.read_csv(
            path,
            encoding="latin-1",
            low_memory=False
        )


def load_datasets():
    separator("1. CHARGEMENT DES DONNEES")

    datasets = {}
    missing_files = []

    for dataset_name, filename in FILES.items():
        path = RAW_DIR / filename

        if not path.exists():
            print(f"[MANQUANT] {filename}")
            missing_files.append(filename)
            continue

        dataframe = load_csv(path)
        datasets[dataset_name] = dataframe

        print(
            f"[OK] {filename:<50} "
            f"{len(dataframe):>12,} ligne(s)"
        )

    if missing_files:
        print("\n[ERREUR] Certains fichiers sont absents :")

        for filename in missing_files:
            print(f"  - {filename}")

        sys.exit(1)

    return datasets


# ============================================================
# OUTILS DE CONTROLE
# ============================================================

def duplicate_key_count(dataframe, columns):
    return int(
        dataframe.duplicated(
            subset=columns,
            keep=False
        ).sum()
    )


def duplicate_key_groups_count(dataframe, columns):
    duplicated_rows = dataframe[
        dataframe.duplicated(
            subset=columns,
            keep=False
        )
    ]

    if duplicated_rows.empty:
        return 0

    return int(
        duplicated_rows[columns]
        .drop_duplicates()
        .shape[0]
    )


def orphan_keys(
    child,
    parent,
    child_key,
    parent_key
):
    child_keys = (
        child[[child_key]]
        .dropna()
        .drop_duplicates()
    )

    parent_keys = (
        parent[[parent_key]]
        .dropna()
        .drop_duplicates()
    )

    merged = child_keys.merge(
        parent_keys,
        how="left",
        left_on=child_key,
        right_on=parent_key,
        indicator=True
    )

    return merged[
        merged["_merge"] == "left_only"
    ].copy()


def parent_without_children(
    parent,
    child,
    parent_key,
    child_key
):
    parent_keys = (
        parent[[parent_key]]
        .dropna()
        .drop_duplicates()
    )

    child_keys = (
        child[[child_key]]
        .dropna()
        .drop_duplicates()
    )

    merged = parent_keys.merge(
        child_keys,
        how="left",
        left_on=parent_key,
        right_on=child_key,
        indicator=True
    )

    return merged[
        merged["_merge"] == "left_only"
    ].copy()


def sample_values(
    dataframe,
    column,
    limit=10
):
    if dataframe.empty:
        return []

    if column not in dataframe.columns:
        return []

    return (
        dataframe[column]
        .dropna()
        .astype(str)
        .drop_duplicates()
        .head(limit)
        .tolist()
    )


# ============================================================
# 2. CONTROLE DES CLES
# ============================================================

def validate_keys(datasets):
    separator("2. CONTROLE DES CLES")

    key_definitions = [
        (
            "customers.customer_id",
            datasets["customers"],
            ["customer_id"],
            True
        ),
        (
            "orders.order_id",
            datasets["orders"],
            ["order_id"],
            True
        ),
        (
            "products.product_id",
            datasets["products"],
            ["product_id"],
            True
        ),
        (
            "sellers.seller_id",
            datasets["sellers"],
            ["seller_id"],
            True
        ),
        (
            "translations.product_category_name",
            datasets["translations"],
            ["product_category_name"],
            True
        ),
        (
            "order_items(order_id, order_item_id)",
            datasets["order_items"],
            ["order_id", "order_item_id"],
            True
        ),
        (
            "payments(order_id, payment_sequential)",
            datasets["payments"],
            ["order_id", "payment_sequential"],
            True
        ),
        (
            "reviews.review_id",
            datasets["reviews"],
            ["review_id"],
            False
        )
    ]

    checks = []

    for (
        key_name,
        dataframe,
        columns,
        expected_unique
    ) in key_definitions:

        null_rows = int(
            dataframe[columns]
            .isna()
            .any(axis=1)
            .sum()
        )

        duplicate_rows = duplicate_key_count(
            dataframe,
            columns
        )

        duplicate_groups = duplicate_key_groups_count(
            dataframe,
            columns
        )

        print(f"\nClé testée : {key_name}")

        print_result(
            "Lignes avec clé NULL",
            null_rows,
            critical=expected_unique
        )

        print_result(
            "Lignes appartenant à une clé dupliquée",
            duplicate_rows,
            critical=expected_unique
        )

        if duplicate_groups > 0:
            print(
                f"             Groupes de clés dupliqués : "
                f"{duplicate_groups:,}"
            )

        if expected_unique:
            status = (
                "PASS"
                if null_rows == 0 and duplicate_rows == 0
                else "FAIL"
            )
        else:
            status = (
                "PASS"
                if duplicate_rows == 0
                else "WARNING"
            )

        checks.append({
            "key": key_name,
            "columns": columns,
            "expected_unique": expected_unique,
            "null_rows": null_rows,
            "duplicate_rows": duplicate_rows,
            "duplicate_groups": duplicate_groups,
            "status": status
        })

    return checks


# ============================================================
# 3. CONTROLE DES RELATIONS
# ============================================================

def validate_relationships(datasets):
    separator("3. CONTROLE DES RELATIONS ENTRE FICHIERS")

    definitions = [
        (
            "orders.customer_id -> customers.customer_id",
            "orders",
            "customers",
            "customer_id",
            "customer_id"
        ),
        (
            "order_items.order_id -> orders.order_id",
            "order_items",
            "orders",
            "order_id",
            "order_id"
        ),
        (
            "order_items.product_id -> products.product_id",
            "order_items",
            "products",
            "product_id",
            "product_id"
        ),
        (
            "order_items.seller_id -> sellers.seller_id",
            "order_items",
            "sellers",
            "seller_id",
            "seller_id"
        ),
        (
            "payments.order_id -> orders.order_id",
            "payments",
            "orders",
            "order_id",
            "order_id"
        ),
        (
            "reviews.order_id -> orders.order_id",
            "reviews",
            "orders",
            "order_id",
            "order_id"
        )
    ]

    results = []

    for (
        relation_name,
        child_name,
        parent_name,
        child_key,
        parent_key
    ) in definitions:

        orphan_df = orphan_keys(
            datasets[child_name],
            datasets[parent_name],
            child_key,
            parent_key
        )

        orphan_count = len(orphan_df)

        print(f"\nRelation : {relation_name}")

        print_result(
            "Clés orphelines",
            orphan_count,
            critical=True
        )

        samples = sample_values(
            orphan_df,
            child_key
        )

        if samples:
            print(
                "             Exemples : "
                + ", ".join(samples)
            )

        results.append({
            "relation": relation_name,
            "child_dataset": child_name,
            "parent_dataset": parent_name,
            "child_key": child_key,
            "parent_key": parent_key,
            "orphan_keys_count": int(orphan_count),
            "sample_orphan_keys": samples,
            "status": (
                "PASS"
                if orphan_count == 0
                else "FAIL"
            )
        })

    return results


# ============================================================
# 4. COUVERTURE DES COMMANDES
# ============================================================

def validate_order_coverage(datasets):
    separator("4. COUVERTURE DES COMMANDES")

    orders = datasets["orders"]

    definitions = [
        (
            "Commandes sans article",
            datasets["order_items"]
        ),
        (
            "Commandes sans paiement",
            datasets["payments"]
        ),
        (
            "Commandes sans avis",
            datasets["reviews"]
        )
    ]

    results = []

    for label, child in definitions:

        missing = parent_without_children(
            orders,
            child,
            "order_id",
            "order_id"
        )

        count = len(missing)

        print_result(
            label,
            count,
            critical=False
        )

        samples = sample_values(
            missing,
            "order_id"
        )

        if samples:
            print(
                "             Exemples : "
                + ", ".join(samples)
            )

        results.append({
            "check": label,
            "count": int(count),
            "sample_order_ids": samples,
            "status": (
                "PASS"
                if count == 0
                else "WARNING"
            )
        })

    return results


# ============================================================
# 5. REFERENTIELS
# ============================================================

def validate_reference_coverage(datasets):
    separator("5. COUVERTURE DES REFERENTIELS")

    products = datasets["products"]
    translations = datasets["translations"]
    customers = datasets["customers"]
    sellers = datasets["sellers"]
    geolocation = datasets["geolocation"]

    results = []

    # --------------------------------------------------------
    # Catégories sans traduction
    # --------------------------------------------------------

    product_categories = (
        products[["product_category_name"]]
        .dropna()
        .drop_duplicates()
    )

    translated_categories = (
        translations[["product_category_name"]]
        .dropna()
        .drop_duplicates()
    )

    category_merge = product_categories.merge(
        translated_categories,
        how="left",
        on="product_category_name",
        indicator=True
    )

    categories_without_translation = category_merge[
        category_merge["_merge"] == "left_only"
    ].copy()

    category_count = len(
        categories_without_translation
    )

    print_result(
        "Catégories produit sans traduction",
        category_count,
        critical=False
    )

    category_samples = sample_values(
        categories_without_translation,
        "product_category_name"
    )

    if category_samples:
        print(
            "             Catégories : "
            + ", ".join(category_samples)
        )

    results.append({
        "check": "product_categories_without_translation",
        "count": int(category_count),
        "sample_values": category_samples,
        "status": (
            "PASS"
            if category_count == 0
            else "WARNING"
        )
    })

    # --------------------------------------------------------
    # Codes postaux clients
    # --------------------------------------------------------

    customer_geo = orphan_keys(
        customers,
        geolocation,
        "customer_zip_code_prefix",
        "geolocation_zip_code_prefix"
    )

    customer_geo_count = len(customer_geo)

    print_result(
        "Codes postaux clients absents de geolocation",
        customer_geo_count,
        critical=False
    )

    customer_samples = sample_values(
        customer_geo,
        "customer_zip_code_prefix"
    )

    if customer_samples:
        print(
            "             Exemples : "
            + ", ".join(customer_samples)
        )

    results.append({
        "check": "customer_zip_without_geolocation",
        "count": int(customer_geo_count),
        "sample_values": customer_samples,
        "status": (
            "PASS"
            if customer_geo_count == 0
            else "WARNING"
        )
    })

    # --------------------------------------------------------
    # Codes postaux vendeurs
    # --------------------------------------------------------

    seller_geo = orphan_keys(
        sellers,
        geolocation,
        "seller_zip_code_prefix",
        "geolocation_zip_code_prefix"
    )

    seller_geo_count = len(seller_geo)

    print_result(
        "Codes postaux vendeurs absents de geolocation",
        seller_geo_count,
        critical=False
    )

    seller_samples = sample_values(
        seller_geo,
        "seller_zip_code_prefix"
    )

    if seller_samples:
        print(
            "             Exemples : "
            + ", ".join(seller_samples)
        )

    results.append({
        "check": "seller_zip_without_geolocation",
        "count": int(seller_geo_count),
        "sample_values": seller_samples,
        "status": (
            "PASS"
            if seller_geo_count == 0
            else "WARNING"
        )
    })

    return results


# ============================================================
# 6. CONTROLES METIER
# ============================================================

def validate_business_rules(datasets):
    separator("6. CONTROLES METIER")

    orders = datasets["orders"].copy()
    order_items = datasets["order_items"].copy()
    payments = datasets["payments"].copy()
    reviews = datasets["reviews"].copy()
    products = datasets["products"].copy()

    results = []

    def add_check(
        name,
        dataframe,
        critical,
        sample_column
    ):
        count = len(dataframe)

        print_result(
            name,
            count,
            critical=critical
        )

        samples = sample_values(
            dataframe,
            sample_column
        )

        if samples:
            print(
                "             Exemples : "
                + ", ".join(samples)
            )

        if count == 0:
            status = "PASS"
        elif critical:
            status = "FAIL"
        else:
            status = "WARNING"

        results.append({
            "check": name,
            "count": int(count),
            "critical": critical,
            "sample_values": samples,
            "status": status
        })

    # --------------------------------------------------------
    # PRIX
    # --------------------------------------------------------

    invalid_prices = order_items[
        order_items["price"].isna()
        | (order_items["price"] <= 0)
    ]

    add_check(
        "Articles avec prix NULL, nul ou négatif",
        invalid_prices,
        True,
        "order_id"
    )

    # --------------------------------------------------------
    # FRET
    # --------------------------------------------------------

    invalid_freight = order_items[
        order_items["freight_value"].isna()
        | (order_items["freight_value"] < 0)
    ]

    add_check(
        "Articles avec fret NULL ou négatif",
        invalid_freight,
        True,
        "order_id"
    )

    # --------------------------------------------------------
    # PAIEMENTS
    # --------------------------------------------------------

    invalid_payments = payments[
        payments["payment_value"].isna()
        | (payments["payment_value"] < 0)
    ]

    add_check(
        "Paiements avec montant NULL ou négatif",
        invalid_payments,
        True,
        "order_id"
    )

    invalid_installments = payments[
        payments["payment_installments"].isna()
        | (payments["payment_installments"] < 0)
    ]

    add_check(
        "Paiements avec nombre de mensualités NULL ou négatif",
        invalid_installments,
        True,
        "order_id"
    )

    # --------------------------------------------------------
    # AVIS
    # --------------------------------------------------------

    invalid_reviews = reviews[
        reviews["review_score"].isna()
        | ~reviews["review_score"].between(1, 5)
    ]

    add_check(
        "Avis avec score hors intervalle 1 à 5",
        invalid_reviews,
        True,
        "review_id"
    )

    # --------------------------------------------------------
    # DIMENSIONS DES PRODUITS
    # --------------------------------------------------------

    dimension_columns = [
        "product_weight_g",
        "product_length_cm",
        "product_height_cm",
        "product_width_cm"
    ]

    for column in dimension_columns:

        invalid_dimension = products[
            products[column].notna()
            & (products[column] <= 0)
        ]

        add_check(
            f"Produits avec {column} <= 0",
            invalid_dimension,
            False,
            "product_id"
        )

    # --------------------------------------------------------
    # CONVERSION DES DATES
    # --------------------------------------------------------

    date_columns = [
        "order_purchase_timestamp",
        "order_approved_at",
        "order_delivered_carrier_date",
        "order_delivered_customer_date",
        "order_estimated_delivery_date"
    ]

    for column in date_columns:
        orders[column] = pd.to_datetime(
            orders[column],
            errors="coerce"
        )

    # --------------------------------------------------------
    # APPROBATION AVANT ACHAT
    # --------------------------------------------------------

    approval_before_purchase = orders[
        orders["order_approved_at"].notna()
        & orders["order_purchase_timestamp"].notna()
        & (
            orders["order_approved_at"]
            < orders["order_purchase_timestamp"]
        )
    ]

    add_check(
        "Commandes approuvées avant leur achat",
        approval_before_purchase,
        True,
        "order_id"
    )

    # --------------------------------------------------------
    # TRANSPORTEUR AVANT APPROBATION
    # --------------------------------------------------------

    carrier_before_approval = orders[
        orders["order_delivered_carrier_date"].notna()
        & orders["order_approved_at"].notna()
        & (
            orders["order_delivered_carrier_date"]
            < orders["order_approved_at"]
        )
    ]

    add_check(
        "Commandes remises au transporteur avant approbation",
        carrier_before_approval,
        False,
        "order_id"
    )

    # --------------------------------------------------------
    # LIVRAISON AVANT TRANSPORTEUR
    # --------------------------------------------------------

    customer_before_carrier = orders[
        orders["order_delivered_customer_date"].notna()
        & orders["order_delivered_carrier_date"].notna()
        & (
            orders["order_delivered_customer_date"]
            < orders["order_delivered_carrier_date"]
        )
    ]

    add_check(
        "Commandes livrées avant remise au transporteur",
        customer_before_carrier,
        True,
        "order_id"
    )

    # --------------------------------------------------------
    # DELIVERED MAIS DATE ABSENTE
    # --------------------------------------------------------

    delivered_without_date = orders[
        orders["order_status"]
        .astype(str)
        .str.lower()
        .eq("delivered")
        & orders["order_delivered_customer_date"].isna()
    ]

    add_check(
        "Commandes delivered sans date de livraison client",
        delivered_without_date,
        True,
        "order_id"
    )

    # --------------------------------------------------------
    # SHIPPING LIMIT DATE >= 2019
    # --------------------------------------------------------

    order_items["shipping_limit_parsed"] = pd.to_datetime(
        order_items["shipping_limit_date"],
        errors="coerce"
    )

    shipping_after_2018 = order_items[
        order_items["shipping_limit_parsed"]
        >= pd.Timestamp("2019-01-01")
    ]

    add_check(
        "Articles avec shipping_limit_date à partir de 2019",
        shipping_after_2018,
        False,
        "order_id"
    )

    return results


# ============================================================
# 7. ANALYSE DES AVIS MULTIPLES
# ============================================================

def validate_reviews(datasets):
    separator("7. ANALYSE DES AVIS MULTIPLES")

    reviews = datasets["reviews"]

    duplicate_review_rows = reviews[
        reviews.duplicated(
            subset=["review_id"],
            keep=False
        )
    ]

    duplicate_order_rows = reviews[
        reviews.duplicated(
            subset=["order_id"],
            keep=False
        )
    ]

    repeated_review_ids = int(
        duplicate_review_rows["review_id"]
        .nunique()
    )

    orders_with_multiple_reviews = int(
        duplicate_order_rows["order_id"]
        .nunique()
    )

    print_result(
        "review_id apparaissant plusieurs fois",
        repeated_review_ids,
        critical=False
    )

    print_result(
        "order_id associé à plusieurs avis",
        orders_with_multiple_reviews,
        critical=False
    )

    return [
        {
            "check": "repeated_review_ids",
            "count": repeated_review_ids,
            "sample_values": sample_values(
                duplicate_review_rows,
                "review_id"
            ),
            "status": (
                "PASS"
                if repeated_review_ids == 0
                else "WARNING"
            )
        },
        {
            "check": "orders_with_multiple_reviews",
            "count": orders_with_multiple_reviews,
            "sample_values": sample_values(
                duplicate_order_rows,
                "order_id"
            ),
            "status": (
                "PASS"
                if orders_with_multiple_reviews == 0
                else "WARNING"
            )
        }
    ]


# ============================================================
# SAUVEGARDE DU RAPPORT
# ============================================================

def save_report(report):
    REPORT_DIR.mkdir(
        parents=True,
        exist_ok=True
    )

    report_path = (
        REPORT_DIR
        / "olist_relationship_validation_report.json"
    )

    with report_path.open(
        "w",
        encoding="utf-8"
    ) as file:
        json.dump(
            report,
            file,
            ensure_ascii=False,
            indent=2
        )

    return report_path


# ============================================================
# SYNTHESE
# ============================================================

def display_summary(report):
    separator("8. SYNTHESE FINALE")

    all_checks = []

    sections = [
        "key_checks",
        "relationship_checks",
        "order_coverage_checks",
        "reference_coverage_checks",
        "business_rule_checks",
        "review_checks"
    ]

    for section in sections:
        all_checks.extend(
            report.get(section, [])
        )

    pass_count = sum(
        1
        for check in all_checks
        if check.get("status") == "PASS"
    )

    warning_count = sum(
        1
        for check in all_checks
        if check.get("status") == "WARNING"
    )

    fail_count = sum(
        1
        for check in all_checks
        if check.get("status") == "FAIL"
    )

    print(
        f"Contrôles exécutés : "
        f"{len(all_checks)}"
    )

    print(
        f"Contrôles réussis  : "
        f"{pass_count}"
    )

    print(
        f"Avertissements     : "
        f"{warning_count}"
    )

    print(
        f"Échecs critiques   : "
        f"{fail_count}"
    )

    if fail_count == 0:
        print(
            "\n[OK] Aucun échec critique détecté."
        )
    else:
        print(
            "\n[ATTENTION] Des anomalies critiques "
            "ont été détectées."
        )

        print(
            "Elles seront étudiées avant les "
            "transformations SILVER."
        )


# ============================================================
# PROGRAMME PRINCIPAL
# ============================================================

def main():
    separator(
        "OLIST - CONTROLE RELATIONNEL ET METIER"
    )

    print(f"Projet      : {PROJECT_ROOT}")
    print(f"Dossier CSV : {RAW_DIR}")

    datasets = load_datasets()

    key_checks = validate_keys(
        datasets
    )

    relationship_checks = validate_relationships(
        datasets
    )

    order_coverage_checks = validate_order_coverage(
        datasets
    )

    reference_coverage_checks = (
        validate_reference_coverage(
            datasets
        )
    )

    business_rule_checks = validate_business_rules(
        datasets
    )

    review_checks = validate_reviews(
        datasets
    )

    report = {
        "generated_at": datetime.now().isoformat(
            timespec="seconds"
        ),
        "raw_directory": str(RAW_DIR),
        "datasets": {
            name: {
                "file": FILES[name],
                "rows": int(len(dataframe)),
                "columns": list(dataframe.columns)
            }
            for name, dataframe
            in datasets.items()
        },
        "key_checks": key_checks,
        "relationship_checks": relationship_checks,
        "order_coverage_checks": order_coverage_checks,
        "reference_coverage_checks":
            reference_coverage_checks,
        "business_rule_checks":
            business_rule_checks,
        "review_checks": review_checks
    }

    report_path = save_report(
        report
    )

    display_summary(
        report
    )

    separator("9. RAPPORT GENERE")

    print(report_path)

    separator("CONTROLE TERMINE")


if __name__ == "__main__":
    main()