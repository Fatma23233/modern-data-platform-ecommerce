from datetime import date
from pathlib import Path

import pandas as pd
from fastapi import FastAPI, HTTPException, Query


# ============================================================
# CONFIGURATION
# ============================================================

PROJECT_ROOT = Path(__file__).resolve().parents[1]

RAW_DIR = PROJECT_ROOT / "data" / "raw"

ORDERS_FILE = RAW_DIR / "olist_orders_dataset.csv"


# ============================================================
# APPLICATION FASTAPI
# ============================================================

app = FastAPI(
    title="Olist Replay API",
    description=(
        "API permettant de rejouer les commandes historiques "
        "Olist par date afin de simuler un flux quotidien."
    ),
    version="1.0.0",
)


# ============================================================
# CHARGEMENT DES COMMANDES
# ============================================================

def load_orders():
    """
    Charge le fichier des commandes Olist et prépare
    la date utilisée pour le rejeu quotidien.
    """

    if not ORDERS_FILE.exists():
        raise RuntimeError(
            f"Fichier introuvable : {ORDERS_FILE}"
        )

    dataframe = pd.read_csv(
        ORDERS_FILE,
        low_memory=False,
    )

    required_columns = [
        "order_id",
        "customer_id",
        "order_status",
        "order_purchase_timestamp",
        "order_approved_at",
        "order_delivered_carrier_date",
        "order_delivered_customer_date",
        "order_estimated_delivery_date",
    ]

    missing_columns = [
        column
        for column in required_columns
        if column not in dataframe.columns
    ]

    if missing_columns:
        raise RuntimeError(
            "Colonnes manquantes dans le fichier orders : "
            + ", ".join(missing_columns)
        )

    dataframe["order_purchase_timestamp"] = pd.to_datetime(
        dataframe["order_purchase_timestamp"],
        errors="coerce",
    )

    dataframe["replay_date"] = (
        dataframe["order_purchase_timestamp"]
        .dt.date
    )

    return dataframe


# Chargement une seule fois au démarrage
orders_df = load_orders()


# ============================================================
# OUTILS
# ============================================================

def clean_value(value):
    """
    Transforme les valeurs pandas en valeurs compatibles JSON.
    """

    if pd.isna(value):
        return None

    if isinstance(value, pd.Timestamp):
        return value.isoformat()

    return value


def dataframe_to_records(dataframe):
    """
    Convertit un DataFrame en liste de dictionnaires JSON.
    """

    records = []

    # On ne renvoie pas la colonne technique replay_date
    columns = [
        column
        for column in dataframe.columns
        if column != "replay_date"
    ]

    for row in dataframe[columns].to_dict(
        orient="records"
    ):
        clean_row = {
            key: clean_value(value)
            for key, value in row.items()
        }

        records.append(clean_row)

    return records


# ============================================================
# ENDPOINT RACINE
# ============================================================

@app.get("/")
def root():
    return {
        "service": "Olist Replay API",
        "version": "1.0.0",
        "status": "running",
        "documentation": "/docs",
    }


# ============================================================
# HEALTH CHECK
# ============================================================

@app.get("/health")
def health():
    """
    Vérifie que l'API fonctionne et que les commandes
    ont correctement été chargées.
    """

    return {
        "status": "healthy",
        "orders_file": ORDERS_FILE.name,
        "orders_loaded": int(len(orders_df)),
    }


# ============================================================
# DATES DISPONIBLES
# ============================================================

@app.get("/dates")
def available_dates():
    """
    Retourne la première date, la dernière date
    et le nombre de dates distinctes disponibles.
    """

    available = (
        orders_df["replay_date"]
        .dropna()
        .sort_values()
        .unique()
        .tolist()
    )

    if not available:
        raise HTTPException(
            status_code=500,
            detail="Aucune date disponible dans les données.",
        )

    return {
        "min_date": available[0],
        "max_date": available[-1],
        "available_dates_count": len(available),
    }


# ============================================================
# LISTE DES DATES
# ============================================================

@app.get("/dates/all")
def all_dates():
    """
    Retourne toutes les dates disponibles avec
    le nombre de commandes pour chaque journée.
    """

    daily_counts = (
        orders_df
        .dropna(subset=["replay_date"])
        .groupby("replay_date")
        .size()
        .reset_index(name="orders_count")
        .sort_values("replay_date")
    )

    result = []

    for _, row in daily_counts.iterrows():
        result.append(
            {
                "date": row["replay_date"],
                "orders_count": int(
                    row["orders_count"]
                ),
            }
        )

    return {
        "dates_count": len(result),
        "dates": result,
    }


# ============================================================
# REJEU DES COMMANDES PAR DATE
# ============================================================

@app.get("/orders")
def get_orders(
    replay_date: date = Query(
        ...,
        alias="date",
        description=(
            "Date des commandes à rejouer "
            "au format YYYY-MM-DD"
        ),
    ),
    limit: int = Query(
        100,
        ge=1,
        le=5000,
        description=(
            "Nombre maximal de commandes retournées"
        ),
    ),
    offset: int = Query(
        0,
        ge=0,
        description=(
            "Position de départ pour la pagination"
        ),
    ),
):
    """
    Retourne les commandes achetées à une date précise.
    """

    daily_orders = orders_df[
        orders_df["replay_date"] == replay_date
    ].copy()

    total_orders = int(
        len(daily_orders)
    )

    if total_orders == 0:
        raise HTTPException(
            status_code=404,
            detail=(
                f"Aucune commande trouvée "
                f"pour la date {replay_date}"
            ),
        )

    paginated_orders = daily_orders.iloc[
        offset:offset + limit
    ]

    records = dataframe_to_records(
        paginated_orders
    )

    returned_orders = len(records)

    return {
        "replay_date": replay_date,
        "total_orders": total_orders,
        "returned_orders": returned_orders,
        "offset": offset,
        "limit": limit,
        "orders": records,
    }


# ============================================================
# STATISTIQUES D'UNE JOURNEE
# ============================================================

@app.get("/orders/stats")
def get_orders_stats(
    replay_date: date = Query(
        ...,
        alias="date",
        description="Date au format YYYY-MM-DD",
    ),
):
    """
    Retourne quelques informations sur le lot journalier
    sans retourner toutes les commandes.
    """

    daily_orders = orders_df[
        orders_df["replay_date"] == replay_date
    ].copy()

    if daily_orders.empty:
        raise HTTPException(
            status_code=404,
            detail=(
                f"Aucune commande trouvée "
                f"pour la date {replay_date}"
            ),
        )

    status_counts = (
        daily_orders["order_status"]
        .value_counts(dropna=False)
        .to_dict()
    )

    clean_status_counts = {
        str(status): int(count)
        for status, count in status_counts.items()
    }

    return {
        "replay_date": replay_date,
        "orders_count": int(
            len(daily_orders)
        ),
        "status_distribution": clean_status_counts,
    }