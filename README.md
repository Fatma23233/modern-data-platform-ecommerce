# Modern Data Platform E-commerce

Plateforme de données e-commerce de bout en bout construite avec **Oracle Database, Python, SQL, Docker et Power BI**.

Le projet couvre toute la chaîne de traitement : ingestion des données, architecture Bronze/Silver/Gold, contrôles qualité, modèle analytique et dashboards Power BI interactifs.

## Architecture

docs/architecture.png

```text
Sources E-commerce
        ↓
      Bronze
        ↓
      Silver
        ↓
       Gold
      ↙    ↘
Contrôles  Power BI
              ↓
          Dashboard
```

## Objectif

Le projet part d'un besoin simple : disposer d'une plateforme fiable pour analyser l'activité d'une marketplace e-commerce sans recalculer les indicateurs directement depuis les données brutes.

J'ai séparé le traitement en trois couches :

- **Bronze** : conservation des données brutes ;
- **Silver** : nettoyage, standardisation et préparation ;
- **Gold** : modèle analytique destiné au reporting.

La couche Gold est ensuite utilisée dans Power BI pour construire les indicateurs et les analyses métier.

## Stack technique

- Python
- Oracle Database Free
- SQL / SQL Developer
- Docker
- Power BI Desktop
- DAX
- Git / GitHub

## Pipeline

```text
Raw Data
   ↓
Bronze
   ↓
Silver
   ↓
Gold
   ↓
Quality Checks
   ↓
Power BI
```

## Modèle Gold

Le modèle analytique contient cinq dimensions :

```text
DIM_DATE
DIM_GEOGRAPHY
DIM_CUSTOMER
DIM_PRODUCT
DIM_SELLER
```

et quatre tables de faits :

```text
FACT_ORDERS
FACT_ORDER_ITEMS
FACT_PAYMENTS
FACT_REVIEWS
```

### Volumes validés

| Table | Lignes |
|---|---:|
| FACT_ORDERS | 99 410 |
| FACT_ORDER_ITEMS | 112 584 |
| FACT_PAYMENTS | 103 852 |
| FACT_REVIEWS | 99 193 |

## Qualité des données

La couche Gold est contrôlée avant son utilisation dans le reporting.

Les contrôles couvrent notamment :

- audit des tables Gold ;
- validation des mesures ;
- réconciliation Silver → Gold ;
- contrôle des KPI.

Résultat final de la réconciliation :

```text
RECONCILIATION_STATUS = PASS
TOTAL_ERRORS          = 0
```

## KPI principaux

| KPI | Résultat |
|---|---:|
| Commandes | 99 410 |
| Valeur produits | 13 585 686,30 |
| Frais de livraison | 2 250 824,91 |
| Valeur totale des items | 15 836 511,20 |
| Total paiements | 16 002 956,50 |
| Panier moyen | 160,57 |
| Délai de livraison moyen | 12,50 jours |
| Taux de retard | 6,78 % |
| Note moyenne | 4,09 / 5 |

## Dashboard Power BI

### 01. Executive Overview

Cette page donne une vue synthétique de l'activité : commandes, ventes, panier moyen, satisfaction, évolution des ventes, statuts de commande et retard de livraison.

docs/executive-overview.png

Principaux indicateurs :

```text
Commandes       99 410
Ventes          15,84 M
Panier moyen    160,57
Note moyenne    4,09 / 5
Taux de retard  6,78 %
```

La page contient également des filtres interactifs par année, mois et statut de commande.

### 02. Ventes & Paiements

La deuxième page approfondit les flux financiers et les comportements de paiement.

docs/sales-payments.png

Principaux indicateurs :

```text
Valeur produits            13,59 M
Frais de livraison          2,25 M
Valeur totale des items    15,84 M
Paiements                  16,00 M
Part frais de livraison    14,21 %
Mensualités moyennes        2,85
```

Cette page permet également d'analyser :

- la répartition des paiements par type ;
- l'évolution mensuelle des paiements ;
- les résultats par année et par mois.

## Modèle Power BI

Le modèle suit une logique dimensionnelle :

```text
Dimension 1 ───────── * Table de faits
```

Les relations sont principalement :

- actives ;
- de type `1:*` ;
- filtrées à sens unique.

Les relations directes entre tables de faits ont été supprimées afin d'éviter les chemins de filtrage ambigus.

## Exemples de mesures DAX

### Total commandes

```DAX
Total Commandes =
DISTINCTCOUNT(FACT_ORDERS[ORDER_ID])
```

### Valeur totale

```DAX
Valeur Totale =
SUM(FACT_ORDER_ITEMS[TOTAL_ITEM_VALUE])
```

### Total paiements

```DAX
Total Paiements =
SUM(FACT_PAYMENTS[PAYMENT_VALUE])
```

### Note moyenne

```DAX
Note Moyenne =
AVERAGE(FACT_REVIEWS[REVIEW_SCORE])
```

### Part des frais de livraison

```DAX
Part Frais Livraison =
DIVIDE(
    [Frais Livraison],
    [Valeur Totale],
    0
)
```

## Organisation du projet

```text
modern-data-platform-ecommerce/
│
├── airflow/
├── api/
├── data/
├── dbt/
├── docs/
│   ├── architecture.png
│   ├── executive-overview.png
│   ├── sales-payments.png
│   └── Rapport_Modern_Data_Platform_Ecommerce_Final.docx
│
├── ingestion/
├── oracle/
│   ├── bronze/
│   ├── silver/
│   ├── gold/
│   └── init/
│
├── powerbi/
├── tests/
├── .gitignore
└── README.md
```

## Principales difficultés rencontrées

### Connexion Oracle / Power BI

Une erreur d'authentification Oracle a été rencontrée lors de la connexion depuis Power BI.

La connexion a été revalidée depuis Oracle avant de reconnecter Power BI au service :

```text
localhost:1522/FREEPDB1
```

### Relations Power BI

La détection automatique avait créé plusieurs chemins de filtrage possibles.

Le modèle a été simplifié afin de conserver des relations déterministes entre dimensions et tables de faits.

### Visualisation des paiements

Un premier graphique normalisait toutes les catégories à 100 %.

Le visuel a été corrigé afin de comparer réellement le nombre de paiements par type.

## Résultat

Le projet fournit une chaîne complète :

```text
Données
   ↓
Ingestion
   ↓
Bronze
   ↓
Silver
   ↓
Gold
   ↓
Contrôles qualité
   ↓
Power BI
   ↓
Dashboard décisionnel
```

L'objectif n'était pas seulement de produire un dashboard, mais de construire une base de données analytique fiable avant la visualisation.

## Documentation

Le rapport détaillé du projet est disponible dans :

```text
docs/Rapport_Modern_Data_Platform_Ecommerce_Final.docx
```

Il documente l'architecture, les différentes couches, le modèle Gold, les contrôles, les KPI, le modèle Power BI et les difficultés rencontrées.

## Auteur

**Fatima BAALI**

Projet Data Engineering / Business Intelligence.
