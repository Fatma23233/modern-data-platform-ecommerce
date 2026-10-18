from pathlib import Path
from datetime import date
import argparse
import os
import sys
import uuid

import oracledb
import pandas as pd
from dotenv import load_dotenv


# ============================================================
# CONFIGURATION GENERALE
# ============================================================

PROJECT_ROOT = Path(__file__).resolve().parents[1]
RAW_DIR = PROJECT_ROOT / "data" / "raw"
ENV_FILE = PROJECT_ROOT / ".env"

load_dotenv(ENV_FILE)


ORACLE_HOST = os.getenv("ORACLE_HOST")
ORACLE_PORT = os.getenv("ORACLE_PORT")
ORACLE_SERVICE = os.getenv("ORACLE_SERVICE")

PIPELINE_USER = os.getenv("PIPELINE_USER")
PIPELINE_PASSWORD = os.getenv("PIPELINE_PASSWORD")


DEFAULT_CHUNK_SIZE = 5000


# ============================================================
# CONFIGURATION DES 9 FICHIERS
# ============================================================

DATASETS = {
    "customers": {
        "file": "olist_customers_dataset.csv",
        "table": "BRONZE.CUSTOMERS_RAW",
        "columns": [
            "customer_id",
            "customer_unique_id",
            "customer_zip_code_prefix",
            "customer_city",
            "customer_state",
        ],
        "input_sizes": [
            50,
            50,
            oracledb.DB_TYPE_NUMBER,
            255,
            10,
            100,
            oracledb.DB_TYPE_DATE,
            255,
        ],
    },

    "geolocation": {
        "file": "olist_geolocation_dataset.csv",
        "table": "BRONZE.GEOLOCATION_RAW",
        "columns": [
            "geolocation_zip_code_prefix",
            "geolocation_lat",
            "geolocation_lng",
            "geolocation_city",
            "geolocation_state",
        ],
        "input_sizes": [
            oracledb.DB_TYPE_NUMBER,
            oracledb.DB_TYPE_NUMBER,
            oracledb.DB_TYPE_NUMBER,
            255,
            10,
            100,
            oracledb.DB_TYPE_DATE,
            255,
        ],
    },

    "order_items": {
        "file": "olist_order_items_dataset.csv",
        "table": "BRONZE.ORDER_ITEMS_RAW",
        "columns": [
            "order_id",
            "order_item_id",
            "product_id",
            "seller_id",
            "shipping_limit_date",
            "price",
            "freight_value",
        ],
        "input_sizes": [
            50,
            oracledb.DB_TYPE_NUMBER,
            50,
            50,
            30,
            oracledb.DB_TYPE_NUMBER,
            oracledb.DB_TYPE_NUMBER,
            100,
            oracledb.DB_TYPE_DATE,
            255,
        ],
    },

    "payments": {
        "file": "olist_order_payments_dataset.csv",
        "table": "BRONZE.PAYMENTS_RAW",
        "columns": [
            "order_id",
            "payment_sequential",
            "payment_type",
            "payment_installments",
            "payment_value",
        ],
        "input_sizes": [
            50,
            oracledb.DB_TYPE_NUMBER,
            50,
            oracledb.DB_TYPE_NUMBER,
            oracledb.DB_TYPE_NUMBER,
            100,
            oracledb.DB_TYPE_DATE,
            255,
        ],
    },

    "reviews": {
        "file": "olist_order_reviews_dataset.csv",
        "table": "BRONZE.REVIEWS_RAW",
        "columns": [
            "review_id",
            "order_id",
            "review_score",
            "review_comment_title",
            "review_comment_message",
            "review_creation_date",
            "review_answer_timestamp",
        ],
        "input_sizes": [
            50,
            50,
            oracledb.DB_TYPE_NUMBER,
            1000,
            oracledb.DB_TYPE_CLOB,
            30,
            30,
            100,
            oracledb.DB_TYPE_DATE,
            255,
        ],
    },

    "orders": {
        "file": "olist_orders_dataset.csv",
        "table": "BRONZE.ORDERS_RAW",
        "columns": [
            "order_id",
            "customer_id",
            "order_status",
            "order_purchase_timestamp",
            "order_approved_at",
            "order_delivered_carrier_date",
            "order_delivered_customer_date",
            "order_estimated_delivery_date",
        ],
        "input_sizes": [
            50,
            50,
            50,
            30,
            30,
            30,
            30,
            30,
            100,
            oracledb.DB_TYPE_DATE,
            255,
        ],
    },

    "products": {
        "file": "olist_products_dataset.csv",
        "table": "BRONZE.PRODUCTS_RAW",
        "columns": [
            "product_id",
            "product_category_name",
            "product_name_lenght",
            "product_description_lenght",
            "product_photos_qty",
            "product_weight_g",
            "product_length_cm",
            "product_height_cm",
            "product_width_cm",
        ],
        "input_sizes": [
            50,
            255,
            oracledb.DB_TYPE_NUMBER,
            oracledb.DB_TYPE_NUMBER,
            oracledb.DB_TYPE_NUMBER,
            oracledb.DB_TYPE_NUMBER,
            oracledb.DB_TYPE_NUMBER,
            oracledb.DB_TYPE_NUMBER,
            oracledb.DB_TYPE_NUMBER,
            100,
            oracledb.DB_TYPE_DATE,
            255,
        ],
    },

    "sellers": {
        "file": "olist_sellers_dataset.csv",
        "table": "BRONZE.SELLERS_RAW",
        "columns": [
            "seller_id",
            "seller_zip_code_prefix",
            "seller_city",
            "seller_state",
        ],
        "input_sizes": [
            50,
            oracledb.DB_TYPE_NUMBER,
            255,
            10,
            100,
            oracledb.DB_TYPE_DATE,
            255,
        ],
    },

    "category_translation": {
        "file": "product_category_name_translation.csv",
        "table": "BRONZE.CATEGORY_TRANSLATION_RAW",
        "columns": [
            "product_category_name",
            "product_category_name_english",
        ],
        "input_sizes": [
            255,
            255,
            100,
            oracledb.DB_TYPE_DATE,
            255,
        ],
    },
}


# ============================================================
# AFFICHAGE
# ============================================================

def separator(title=""):
    print("\n" + "=" * 100)

    if title:
        print(title)
        print("=" * 100)


# ============================================================
# VALIDATION DES VARIABLES
# ============================================================

def validate_environment():
    required_variables = {
        "ORACLE_HOST": ORACLE_HOST,
        "ORACLE_PORT": ORACLE_PORT,
        "ORACLE_SERVICE": ORACLE_SERVICE,
        "PIPELINE_USER": PIPELINE_USER,
        "PIPELINE_PASSWORD": PIPELINE_PASSWORD,
    }

    missing_variables = [
        name
        for name, value in required_variables.items()
        if not value
    ]

    if missing_variables:
        print("[ERREUR] Variables absentes du fichier .env :")

        for variable in missing_variables:
            print(f"  - {variable}")

        sys.exit(1)

    if not RAW_DIR.exists():
        print(f"[ERREUR] Dossier CSV introuvable : {RAW_DIR}")
        sys.exit(1)


# ============================================================
# CONNEXION ORACLE
# ============================================================

def get_dsn():
    return (
        f"{ORACLE_HOST}:"
        f"{ORACLE_PORT}/"
        f"{ORACLE_SERVICE}"
    )


def create_connection():
    return oracledb.connect(
        user=PIPELINE_USER,
        password=PIPELINE_PASSWORD,
        dsn=get_dsn(),
    )


# ============================================================
# NORMALISATION DES VALEURS PANDAS
# ============================================================

def normalize_value(value):
    """
    Convertit les valeurs pandas/numpy vers des types Python
    compatibles avec python-oracledb.
    """

    if value is None:
        return None

    try:
        if pd.isna(value):
            return None
    except (TypeError, ValueError):
        pass

    # Conversion des types numpy vers les types Python natifs
    if hasattr(value, "item"):
        try:
            return value.item()
        except (ValueError, AttributeError):
            pass

    return value


def dataframe_to_rows(
    dataframe,
    columns,
    batch_id,
    batch_date,
    source_file,
):
    """
    Transforme un DataFrame en tuples utilisables par
    cursor.executemany().
    """

    rows = []

    selected_dataframe = dataframe[columns]

    for values in selected_dataframe.itertuples(
        index=False,
        name=None,
    ):
        normalized_values = tuple(
            normalize_value(value)
            for value in values
        )

        complete_row = normalized_values + (
            batch_id,
            batch_date,
            source_file,
        )

        rows.append(complete_row)

    return rows


# ============================================================
# GENERATION SQL
# ============================================================

def build_insert_sql(table_name, source_columns):
    """
    Construit l'instruction INSERT avec les colonnes source
    et les métadonnées BRONZE.
    """

    oracle_columns = [
        column.upper()
        for column in source_columns
    ]

    oracle_columns.extend([
        "BATCH_ID",
        "BATCH_DATE",
        "SOURCE_FILE",
    ])

    column_list = ", ".join(oracle_columns)

    bind_list = ", ".join(
        f":{index}"
        for index in range(
            1,
            len(oracle_columns) + 1,
        )
    )

    return (
        f"INSERT INTO {table_name} "
        f"({column_list}) "
        f"VALUES ({bind_list})"
    )


# ============================================================
# SUIVI DU BATCH
# ============================================================

def create_batch_log(
    connection,
    batch_id,
    batch_date,
    source_name,
    target_table,
):
    with connection.cursor() as cursor:
        cursor.execute(
            """
            INSERT INTO BRONZE.BATCH_LOG (
                BATCH_ID,
                BATCH_DATE,
                SOURCE_NAME,
                TARGET_TABLE,
                STARTED_AT,
                ROWS_READ,
                ROWS_INSERTED,
                STATUS
            )
            VALUES (
                :batch_id,
                :batch_date,
                :source_name,
                :target_table,
                SYSTIMESTAMP,
                0,
                0,
                'RUNNING'
            )
            """,
            batch_id=batch_id,
            batch_date=batch_date,
            source_name=source_name,
            target_table=target_table,
        )

    connection.commit()


def mark_batch_success(
    connection,
    batch_id,
    rows_read,
    rows_inserted,
):
    with connection.cursor() as cursor:
        cursor.execute(
            """
            UPDATE BRONZE.BATCH_LOG
            SET
                FINISHED_AT = SYSTIMESTAMP,
                ROWS_READ = :rows_read,
                ROWS_INSERTED = :rows_inserted,
                STATUS = 'SUCCESS',
                ERROR_MESSAGE = NULL
            WHERE BATCH_ID = :batch_id
            """,
            rows_read=rows_read,
            rows_inserted=rows_inserted,
            batch_id=batch_id,
        )

    connection.commit()


def mark_batch_failed(
    connection,
    batch_id,
    rows_read,
    error_message,
):
    clean_error_message = str(error_message)[:4000]

    with connection.cursor() as cursor:
        cursor.execute(
            """
            UPDATE BRONZE.BATCH_LOG
            SET
                FINISHED_AT = SYSTIMESTAMP,
                ROWS_READ = :rows_read,
                ROWS_INSERTED = 0,
                STATUS = 'FAILED',
                ERROR_MESSAGE = :error_message
            WHERE BATCH_ID = :batch_id
            """,
            rows_read=rows_read,
            error_message=clean_error_message,
            batch_id=batch_id,
        )

    connection.commit()


# ============================================================
# CHARGEMENT D'UN FICHIER
# ============================================================

def load_dataset(
    dataset_name,
    config,
    batch_date,
    chunk_size,
):
    source_file = config["file"]
    table_name = config["table"]
    columns = config["columns"]
    input_sizes = config["input_sizes"]

    csv_path = RAW_DIR / source_file

    if not csv_path.exists():
        raise FileNotFoundError(
            f"Fichier introuvable : {csv_path}"
        )

    batch_id = (
        f"{dataset_name}-"
        f"{batch_date.isoformat()}-"
        f"{uuid.uuid4().hex[:8]}"
    )

    rows_read = 0
    rows_inserted = 0

    separator(
        f"CHARGEMENT : {source_file} -> {table_name}"
    )

    print(f"Batch ID    : {batch_id}")
    print(f"Batch date  : {batch_date}")
    print(f"Chunk size  : {chunk_size:,}")

    # Une connexion dédiée au journal.
    # Le statut RUNNING reste enregistré même si le chargement
    # principal doit être annulé.
    log_connection = create_connection()

    main_connection = None

    try:
        create_batch_log(
            connection=log_connection,
            batch_id=batch_id,
            batch_date=batch_date,
            source_name=source_file,
            target_table=table_name,
        )

        main_connection = create_connection()

        insert_sql = build_insert_sql(
            table_name=table_name,
            source_columns=columns,
        )

        with main_connection.cursor() as cursor:

            # ------------------------------------------------
            # IDEMPOTENCE DU CHARGEMENT INITIAL
            #
            # On remplace toutes les lignes issues du même
            # fichier source.
            # ------------------------------------------------

            cursor.execute(
                f"""
                DELETE FROM {table_name}
                WHERE SOURCE_FILE = :source_file
                """,
                source_file=source_file,
            )

            deleted_rows = cursor.rowcount

            print(
                f"Anciennes lignes supprimées : "
                f"{deleted_rows:,}"
            )

            cursor.setinputsizes(
                *input_sizes
            )

            # ------------------------------------------------
            # LECTURE ET INSERTION PAR CHUNKS
            # ------------------------------------------------

            chunks = pd.read_csv(
                csv_path,
                chunksize=chunk_size,
                low_memory=False,
            )

            for chunk_number, dataframe in enumerate(
                chunks,
                start=1,
            ):
                missing_columns = [
                    column
                    for column in columns
                    if column not in dataframe.columns
                ]

                if missing_columns:
                    raise ValueError(
                        f"Colonnes manquantes dans "
                        f"{source_file} : "
                        + ", ".join(missing_columns)
                    )

                rows = dataframe_to_rows(
                    dataframe=dataframe,
                    columns=columns,
                    batch_id=batch_id,
                    batch_date=batch_date,
                    source_file=source_file,
                )

                rows_read += len(rows)

                cursor.executemany(
                    insert_sql,
                    rows,
                )

                rows_inserted += len(rows)

                print(
                    f"Chunk {chunk_number:03d} : "
                    f"{len(rows):>8,} lignes "
                    f"| total : {rows_inserted:>10,}"
                )

        # DELETE et INSERT appartiennent à la même transaction.
        main_connection.commit()

        mark_batch_success(
            connection=log_connection,
            batch_id=batch_id,
            rows_read=rows_read,
            rows_inserted=rows_inserted,
        )

        print(
            f"[SUCCESS] {source_file} : "
            f"{rows_inserted:,} lignes insérées."
        )

        return {
            "dataset": dataset_name,
            "source_file": source_file,
            "target_table": table_name,
            "batch_id": batch_id,
            "rows_read": rows_read,
            "rows_inserted": rows_inserted,
            "status": "SUCCESS",
        }

    except Exception as error:

        if main_connection is not None:
            main_connection.rollback()

        try:
            mark_batch_failed(
                connection=log_connection,
                batch_id=batch_id,
                rows_read=rows_read,
                error_message=error,
            )
        except Exception as log_error:
            print(
                "[ERREUR] Impossible de mettre à jour "
                "BATCH_LOG :"
            )
            print(log_error)

        print(
            f"[FAILED] {source_file}"
        )
        print(error)

        return {
            "dataset": dataset_name,
            "source_file": source_file,
            "target_table": table_name,
            "batch_id": batch_id,
            "rows_read": rows_read,
            "rows_inserted": 0,
            "status": "FAILED",
            "error": str(error),
        }

    finally:
        if main_connection is not None:
            main_connection.close()

        log_connection.close()


# ============================================================
# VERIFICATION DES VOLUMES ORACLE
# ============================================================

def verify_oracle_counts():
    separator("VERIFICATION DES VOLUMES ORACLE")

    results = {}

    with create_connection() as connection:
        with connection.cursor() as cursor:

            for dataset_name, config in DATASETS.items():
                table_name = config["table"]

                cursor.execute(
                    f"SELECT COUNT(*) FROM {table_name}"
                )

                row_count = int(
                    cursor.fetchone()[0]
                )

                results[dataset_name] = row_count

                print(
                    f"{table_name:<45} "
                    f"{row_count:>12,}"
                )

    return results


# ============================================================
# ARGUMENTS
# ============================================================

def parse_arguments():
    parser = argparse.ArgumentParser(
        description=(
            "Charge les neuf CSV Olist dans les "
            "tables BRONZE Oracle."
        )
    )

    parser.add_argument(
        "--batch-date",
        required=True,
        help=(
            "Date fonctionnelle du snapshot initial "
            "au format YYYY-MM-DD."
        ),
    )

    parser.add_argument(
        "--dataset",
        choices=["all"] + list(DATASETS.keys()),
        default="all",
        help=(
            "Dataset à charger. Par défaut : all."
        ),
    )

    parser.add_argument(
        "--chunk-size",
        type=int,
        default=DEFAULT_CHUNK_SIZE,
        help=(
            "Nombre de lignes par bloc d'insertion. "
            f"Par défaut : {DEFAULT_CHUNK_SIZE}."
        ),
    )

    return parser.parse_args()


# ============================================================
# PROGRAMME PRINCIPAL
# ============================================================

def main():
    separator("OLIST - CHARGEMENT INITIAL BRONZE")

    validate_environment()

    arguments = parse_arguments()

    try:
        batch_date = date.fromisoformat(
            arguments.batch_date
        )
    except ValueError:
        print(
            "[ERREUR] --batch-date doit respecter "
            "le format YYYY-MM-DD."
        )
        sys.exit(1)

    if arguments.chunk_size <= 0:
        print(
            "[ERREUR] --chunk-size doit être supérieur à zéro."
        )
        sys.exit(1)

    print(f"Oracle      : {get_dsn()}")
    print(f"Utilisateur : {PIPELINE_USER}")
    print(f"Batch date  : {batch_date}")
    print(f"Dataset     : {arguments.dataset}")
    print(f"Chunk size  : {arguments.chunk_size:,}")

    if arguments.dataset == "all":
        selected_datasets = DATASETS.items()
    else:
        selected_datasets = [
            (
                arguments.dataset,
                DATASETS[arguments.dataset],
            )
        ]

    results = []

    for dataset_name, config in selected_datasets:
        result = load_dataset(
            dataset_name=dataset_name,
            config=config,
            batch_date=batch_date,
            chunk_size=arguments.chunk_size,
        )

        results.append(result)

        # On arrête le chargement global dès qu'un fichier échoue.
        if result["status"] == "FAILED":
            print(
                "\n[ARRET] Le chargement global est interrompu."
            )
            break

    oracle_counts = verify_oracle_counts()

    separator("SYNTHESE DU CHARGEMENT")

    for result in results:
        print(
            f"{result['dataset']:<25} "
            f"{result['status']:<10} "
            f"{result['rows_inserted']:>12,} ligne(s)"
        )

    success_count = sum(
        result["status"] == "SUCCESS"
        for result in results
    )

    failed_count = sum(
        result["status"] == "FAILED"
        for result in results
    )

    print()
    print(f"Chargements réussis : {success_count}")
    print(f"Chargements échoués : {failed_count}")

    if failed_count > 0:
        print(
            "\n[FAILED] Le chargement BRONZE "
            "n'est pas complètement validé."
        )
        sys.exit(1)

    print(
        "\n[SUCCESS] Le chargement BRONZE "
        "est terminé."
    )

    print(
        "\nProchaine vérification : comparer les "
        "volumes Oracle avec les volumes CSV."
    )


if __name__ == "__main__":
    main()