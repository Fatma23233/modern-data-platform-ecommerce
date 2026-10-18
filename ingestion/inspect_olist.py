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

EXPECTED_FILES = [
    "olist_customers_dataset.csv",
    "olist_geolocation_dataset.csv",
    "olist_order_items_dataset.csv",
    "olist_order_payments_dataset.csv",
    "olist_order_reviews_dataset.csv",
    "olist_orders_dataset.csv",
    "olist_products_dataset.csv",
    "olist_sellers_dataset.csv",
    "product_category_name_translation.csv",
]

# Colonnes de dates connues dans les fichiers Olist.
# On les utilise uniquement si elles existent réellement dans le CSV.
DATE_COLUMNS = {
    "olist_orders_dataset.csv": [
        "order_purchase_timestamp",
        "order_approved_at",
        "order_delivered_carrier_date",
        "order_delivered_customer_date",
        "order_estimated_delivery_date",
    ],
    "olist_order_items_dataset.csv": [
        "shipping_limit_date",
    ],
    "olist_order_reviews_dataset.csv": [
        "review_creation_date",
        "review_answer_timestamp",
    ],
}


# ============================================================
# UTILITAIRES
# ============================================================

def separator(title: str = "") -> None:
    print("\n" + "=" * 90)
    if title:
        print(title)
        print("=" * 90)


def human_size(size_bytes: int) -> str:
    """Convertit une taille en octets vers une valeur lisible."""
    units = ["B", "KB", "MB", "GB"]

    size = float(size_bytes)

    for unit in units:
        if size < 1024:
            return f"{size:.2f} {unit}"
        size /= 1024

    return f"{size:.2f} TB"


def load_csv(path: Path) -> pd.DataFrame:
    """
    Charge un CSV.
    UTF-8 est tenté en premier.
    latin-1 sert uniquement de fallback si l'encodage UTF-8 échoue.
    """
    try:
        return pd.read_csv(path, low_memory=False)
    except UnicodeDecodeError:
        print("  [INFO] UTF-8 impossible, nouvel essai avec latin-1.")
        return pd.read_csv(path, encoding="latin-1", low_memory=False)


# ============================================================
# VERIFICATION DES FICHIERS
# ============================================================

def check_expected_files():
    separator("1. VERIFICATION DES FICHIERS")

    if not RAW_DIR.exists():
        print(f"[ERREUR] Dossier introuvable : {RAW_DIR}")
        print(
            "\nStructure attendue :\n"
            "data/\n"
            "  raw/\n"
            "    olist_orders_dataset.csv\n"
            "    ..."
        )
        sys.exit(1)

    existing_files = {
        path.name
        for path in RAW_DIR.glob("*.csv")
    }

    missing_files = []

    for filename in EXPECTED_FILES:
        if filename in existing_files:
            print(f"[OK]      {filename}")
        else:
            print(f"[MANQUANT] {filename}")
            missing_files.append(filename)

    extra_files = sorted(existing_files - set(EXPECTED_FILES))

    if extra_files:
        print("\nFichiers CSV supplémentaires détectés :")
        for filename in extra_files:
            print(f"  - {filename}")

    print()
    print(f"Fichiers attendus : {len(EXPECTED_FILES)}")
    print(f"Fichiers présents : {len(existing_files)}")
    print(f"Fichiers manquants : {len(missing_files)}")

    return missing_files, extra_files


# ============================================================
# ANALYSE D'UN CSV
# ============================================================

def inspect_csv(path: Path):
    separator(f"ANALYSE : {path.name}")

    file_size = path.stat().st_size

    try:
        df = load_csv(path)

    except Exception as exc:
        print(f"[ERREUR] Impossible de lire {path.name}")
        print(f"Détail : {exc}")

        return {
            "file": path.name,
            "status": "ERROR",
            "error": str(exc),
        }

    rows, columns = df.shape

    # --------------------------------------------------------
    # Informations générales
    # --------------------------------------------------------

    print(f"Taille fichier       : {human_size(file_size)}")
    print(f"Nombre de lignes     : {rows:,}")
    print(f"Nombre de colonnes   : {columns:,}")

    # --------------------------------------------------------
    # Colonnes
    # --------------------------------------------------------

    print("\nColonnes :")

    for index, column in enumerate(df.columns, start=1):
        print(
            f"  {index:02d}. "
            f"{column:<40} "
            f"dtype={str(df[column].dtype)}"
        )

    # --------------------------------------------------------
    # Valeurs manquantes
    # --------------------------------------------------------

    null_counts = df.isna().sum()
    null_counts = null_counts[null_counts > 0].sort_values(
        ascending=False
    )

    total_nulls = int(df.isna().sum().sum())

    print("\nValeurs manquantes :")
    print(f"Total NULL/NaN : {total_nulls:,}")

    null_details = {}

    if total_nulls == 0:
        print("  Aucune valeur manquante détectée.")
    else:
        for column, count in null_counts.items():
            percentage = (
                (count / rows) * 100 if rows > 0 else 0
            )

            print(
                f"  {column:<40} "
                f"{int(count):>10,} "
                f"({percentage:6.2f} %)"
            )

            null_details[column] = {
                "count": int(count),
                "percentage": round(float(percentage), 4),
            }

    # --------------------------------------------------------
    # Doublons complets
    # --------------------------------------------------------

    duplicate_rows = int(df.duplicated().sum())

    print("\nDoublons complets :")
    print(f"  {duplicate_rows:,} ligne(s) dupliquée(s)")

    # --------------------------------------------------------
    # Unicité des colonnes
    # --------------------------------------------------------

    print("\nCardinalité des colonnes :")

    cardinality = {}

    for column in df.columns:
        unique_count = int(df[column].nunique(dropna=True))
        cardinality[column] = unique_count

        print(
            f"  {column:<40} "
            f"{unique_count:>10,} valeurs distinctes"
        )

    # --------------------------------------------------------
    # Analyse des dates
    # --------------------------------------------------------

    detected_dates = {}

    configured_date_columns = DATE_COLUMNS.get(path.name, [])

    existing_date_columns = [
        column
        for column in configured_date_columns
        if column in df.columns
    ]

    if existing_date_columns:
        print("\nPlages temporelles :")

        for column in existing_date_columns:

            parsed_dates = pd.to_datetime(
                df[column],
                errors="coerce"
            )

            valid_dates = parsed_dates.dropna()

            invalid_dates = int(
                df[column].notna().sum()
                - valid_dates.shape[0]
            )

            if valid_dates.empty:
                print(
                    f"  {column:<40} "
                    "aucune date valide détectée"
                )

                detected_dates[column] = {
                    "min": None,
                    "max": None,
                    "invalid_values": invalid_dates,
                }

                continue

            min_date = valid_dates.min()
            max_date = valid_dates.max()

            print(
                f"  {column:<40} "
                f"{min_date} -> {max_date}"
            )

            if invalid_dates > 0:
                print(
                    f"    valeurs non convertibles : "
                    f"{invalid_dates:,}"
                )

            detected_dates[column] = {
                "min": str(min_date),
                "max": str(max_date),
                "invalid_values": invalid_dates,
            }

    # --------------------------------------------------------
    # Mémoire
    # --------------------------------------------------------

    memory_bytes = int(
        df.memory_usage(deep=True).sum()
    )

    print("\nMémoire DataFrame :")
    print(f"  {human_size(memory_bytes)}")

    # --------------------------------------------------------
    # Rapport
    # --------------------------------------------------------

    return {
        "file": path.name,
        "status": "OK",
        "file_size_bytes": file_size,
        "rows": rows,
        "columns_count": columns,
        "columns": list(df.columns),
        "dtypes": {
            column: str(dtype)
            for column, dtype in df.dtypes.items()
        },
        "total_nulls": total_nulls,
        "nulls_by_column": null_details,
        "duplicate_rows": duplicate_rows,
        "unique_values": cardinality,
        "date_ranges": detected_dates,
        "memory_bytes": memory_bytes,
    }


# ============================================================
# SYNTHESE GLOBALE
# ============================================================

def display_summary(results):
    separator("2. SYNTHESE GLOBALE")

    valid_results = [
        result
        for result in results
        if result.get("status") == "OK"
    ]

    if not valid_results:
        print("Aucun fichier n'a pu être analysé.")
        return

    print(
        f"{'FICHIER':45}"
        f"{'LIGNES':>12}"
        f"{'COLONNES':>12}"
        f"{'NULL':>12}"
        f"{'DOUBLONS':>12}"
    )

    print("-" * 93)

    total_rows = 0
    total_nulls = 0
    total_duplicates = 0

    for result in valid_results:

        total_rows += result["rows"]
        total_nulls += result["total_nulls"]
        total_duplicates += result["duplicate_rows"]

        print(
            f"{result['file'][:44]:45}"
            f"{result['rows']:>12,}"
            f"{result['columns_count']:>12,}"
            f"{result['total_nulls']:>12,}"
            f"{result['duplicate_rows']:>12,}"
        )

    print("-" * 93)

    print(f"Total lignes lues      : {total_rows:,}")
    print(f"Total NULL/NaN         : {total_nulls:,}")
    print(f"Total doublons complets: {total_duplicates:,}")

    print(
        "\nAttention : le total des lignes correspond à la somme "
        "des lignes des différents CSV, pas à un nombre de "
        "commandes uniques."
    )


# ============================================================
# EXPORT JSON
# ============================================================

def save_report(results, missing_files, extra_files):
    REPORT_DIR.mkdir(parents=True, exist_ok=True)

    report_path = REPORT_DIR / "olist_inventory_report.json"

    report = {
        "generated_at": datetime.now().isoformat(
            timespec="seconds"
        ),
        "raw_directory": str(RAW_DIR),
        "expected_files": EXPECTED_FILES,
        "missing_files": missing_files,
        "extra_files": extra_files,
        "files": results,
    }

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

    separator("3. RAPPORT GENERE")
    print(report_path)


# ============================================================
# PROGRAMME PRINCIPAL
# ============================================================

def main():
    separator("OLIST - INVENTAIRE ET CONTROLE DES SOURCES")

    print(f"Projet       : {PROJECT_ROOT}")
    print(f"Dossier CSV  : {RAW_DIR}")

    missing_files, extra_files = check_expected_files()

    if missing_files:
        print(
            "\n[ATTENTION] Certains fichiers attendus sont absents."
        )
        print(
            "L'analyse continue uniquement avec les fichiers présents."
        )

    results = []

    for filename in EXPECTED_FILES:
        path = RAW_DIR / filename

        if path.exists():
            result = inspect_csv(path)
            results.append(result)

    display_summary(results)

    save_report(
        results,
        missing_files,
        extra_files
    )

    separator("CONTROLE TERMINE")

    errors = [
        result
        for result in results
        if result.get("status") == "ERROR"
    ]

    print(f"Fichiers analysés : {len(results)}")
    print(f"Fichiers manquants: {len(missing_files)}")
    print(f"Erreurs de lecture: {len(errors)}")

    if not missing_files and not errors:
        print(
            "\n[OK] Tous les fichiers attendus ont été analysés."
        )
        print(
            "Le corpus est prêt pour l'étape suivante de validation."
        )
    else:
        print(
            "\n[ATTENTION] Le corpus nécessite une vérification "
            "avant ingestion."
        )


if __name__ == "__main__":
    main()