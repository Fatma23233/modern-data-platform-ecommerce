from pathlib import Path
import os
import sys

import oracledb
from dotenv import load_dotenv


# Configuration
PROJECT_ROOT = Path(__file__).resolve().parents[1]
load_dotenv(PROJECT_ROOT / ".env")

host = os.getenv("ORACLE_HOST")
port = os.getenv("ORACLE_PORT")
service = os.getenv("ORACLE_SERVICE")
user = os.getenv("PIPELINE_USER")
password = os.getenv("PIPELINE_PASSWORD")

required_values = {
    "ORACLE_HOST": host,
    "ORACLE_PORT": port,
    "ORACLE_SERVICE": service,
    "PIPELINE_USER": user,
    "PIPELINE_PASSWORD": password,
}

missing_values = [
    name
    for name, value in required_values.items()
    if not value
]

if missing_values:
    print("[ERREUR] Variables manquantes dans .env :")

    for name in missing_values:
        print(f"  - {name}")

    sys.exit(1)


dsn = f"{host}:{port}/{service}"

print("=" * 70)
print("TEST DES DROITS PIPELINE SUR BRONZE")
print("=" * 70)

try:
    with oracledb.connect(
        user=user,
        password=password,
        dsn=dsn,
    ) as connection:

        with connection.cursor() as cursor:

            cursor.execute(
                "SELECT COUNT(*) FROM BRONZE.ORDERS_RAW"
            )

            orders_count = cursor.fetchone()[0]

            cursor.execute(
                "SELECT COUNT(*) FROM BRONZE.BATCH_LOG"
            )

            batches_count = cursor.fetchone()[0]

        print("[OK] Connexion avec PIPELINE")
        print("[OK] Lecture de BRONZE.ORDERS_RAW")
        print(f"ORDERS_RAW = {orders_count}")

        print("[OK] Lecture de BRONZE.BATCH_LOG")
        print(f"BATCH_LOG = {batches_count}")

        print("\n[OK] Accès PIPELINE vers BRONZE validé.")

except oracledb.Error as error:
    print("[ERREUR] Test Oracle impossible :")
    print(error)
    sys.exit(1)