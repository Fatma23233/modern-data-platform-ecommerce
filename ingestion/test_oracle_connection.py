from pathlib import Path
import os
import sys

import oracledb
from dotenv import load_dotenv


# ============================================================
# CONFIGURATION
# ============================================================

PROJECT_ROOT = Path(__file__).resolve().parents[1]
ENV_FILE = PROJECT_ROOT / ".env"

# Chargement du fichier .env
load_dotenv(ENV_FILE)


ORACLE_HOST = os.getenv("ORACLE_HOST")
ORACLE_PORT = os.getenv("ORACLE_PORT")
ORACLE_SERVICE = os.getenv("ORACLE_SERVICE")

PIPELINE_USER = os.getenv("PIPELINE_USER")
PIPELINE_PASSWORD = os.getenv("PIPELINE_PASSWORD")


# ============================================================
# VERIFICATION DES VARIABLES D'ENVIRONNEMENT
# ============================================================

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
    print("[ERREUR] Variables manquantes dans le fichier .env :")

    for variable in missing_variables:
        print(f"  - {variable}")

    sys.exit(1)


# ============================================================
# CONSTRUCTION DU DSN
# ============================================================

dsn = (
    f"{ORACLE_HOST}:"
    f"{ORACLE_PORT}/"
    f"{ORACLE_SERVICE}"
)


# ============================================================
# TEST DE CONNEXION
# ============================================================

print("=" * 70)
print("TEST CONNEXION PYTHON -> ORACLE")
print("=" * 70)

print(f"Hôte    : {ORACLE_HOST}")
print(f"Port    : {ORACLE_PORT}")
print(f"Service : {ORACLE_SERVICE}")
print(f"User    : {PIPELINE_USER}")

print("\nConnexion en cours...")


try:

    with oracledb.connect(
        user=PIPELINE_USER,
        password=PIPELINE_PASSWORD,
        dsn=dsn,
    ) as connection:

        print("[OK] Connexion Oracle réussie.")

        # ----------------------------------------------------
        # Mode python-oracledb
        # ----------------------------------------------------

        print(
            f"[OK] Mode python-oracledb : "
            f"{'THIN' if connection.thin else 'THICK'}"
        )

        # ----------------------------------------------------
        # Création du curseur
        # ----------------------------------------------------

        with connection.cursor() as cursor:

            # ------------------------------------------------
            # Vérification de l'utilisateur et du service
            # ------------------------------------------------

            cursor.execute(
                """
                SELECT
                    USER,
                    SYS_CONTEXT(
                        'USERENV',
                        'SERVICE_NAME'
                    )
                FROM DUAL
                """
            )

            result = cursor.fetchone()

            user = result[0]
            service = result[1]

            print(
                f"[OK] Utilisateur connecté : {user}"
            )

            print(
                f"[OK] Service Oracle       : {service}"
            )

            # ------------------------------------------------
            # Test SQL minimal
            # ------------------------------------------------

            cursor.execute(
                "SELECT 1 FROM DUAL"
            )

            result = cursor.fetchone()[0]

            if result == 1:

                print(
                    "[OK] SELECT 1 FROM DUAL : réussi"
                )

            else:

                print(
                    "[ERREUR] Résultat SQL inattendu"
                )

                sys.exit(1)


        print("\n" + "=" * 70)
        print("CONNEXION PIPELINE VALIDEE")
        print("=" * 70)


except oracledb.Error as error:

    print("\n" + "=" * 70)
    print("[ERREUR] CONNEXION ORACLE IMPOSSIBLE")
    print("=" * 70)

    print(error)

    sys.exit(1)