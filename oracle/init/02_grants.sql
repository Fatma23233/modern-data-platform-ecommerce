-- Privileges minimaux de base pour les proprietaires de schemas.
GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE SEQUENCE TO BRONZE;
GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE SEQUENCE TO SILVER;
GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE SEQUENCE TO GOLD;
GRANT CREATE SESSION TO PIPELINE;

-- Les droits inter-schemas de PIPELINE seront ajoutes progressivement
-- quand les besoins reels de l'ingestion, dbt et Airflow seront definis.
