# Modern Data Platform Oracle - Etape 1

Objectif : mettre en place Oracle dans Docker avec persistance des donnees et separer les schemas BRONZE, SILVER, GOLD et le compte technique PIPELINE.

## 1. Architecture

- BRONZE : donnees brutes
- SILVER : donnees nettoyees et typees
- GOLD : modele analytique
- PIPELINE : utilisateur technique pour les traitements automatises
- SYSTEM : administration uniquement

## 2. Preparation

1. Installer Docker Desktop et SQL Developer.
2. Copier `.env.example` vers `.env`.
3. Remplacer les mots de passe d'exemple.
4. Ne jamais versionner `.env`.

## 3. Demarrage Oracle

```powershell
docker compose up -d
docker compose ps
docker logs oracle-data-platform
```

Le service Oracle expose le port `1521` et utilise le volume nomme `oracle_data`.

## 4. Schemas Oracle

Les scripts du dossier `oracle/init/` preparent :

- `BRONZE`
- `SILVER`
- `GOLD`
- `PIPELINE`

`SYSTEM` reste reserve aux operations d'administration.

> Remarque : selon le comportement exact de l'image Oracle retenue, l'execution automatique des scripts d'initialisation et le service name doivent etre verifies avant utilisation. Les scripts SQL restent executables manuellement depuis SQL Developer si necessaire.

## 5. Validation SQL Developer

Tester chaque connexion puis executer :

```sql
SELECT USER FROM dual;
```

Le resultat doit correspondre au compte de connexion, par exemple `BRONZE`, `SILVER`, `GOLD` ou `PIPELINE`.

Pour verifier les quatre comptes depuis un compte administrateur, utiliser `oracle/init/03_verify.sql`.

## 6. Test de persistance

Creer une petite table de test dans BRONZE :

```sql
CREATE TABLE persistence_test (
    id NUMBER PRIMARY KEY,
    message VARCHAR2(100)
);

INSERT INTO persistence_test VALUES (1, 'volume-ok');
COMMIT;
```

Redemarrer ensuite le conteneur sans supprimer les volumes :

```powershell
docker compose down
docker compose up -d
```

Reconnecter BRONZE et verifier :

```sql
SELECT * FROM persistence_test;
```

Ne pas utiliser `docker compose down -v` pour ce test, car cette commande supprime les volumes associes.

## 7. Checklist de fin d'etape

- [ ] Docker fonctionne
- [ ] Oracle demarre
- [ ] Le port 1521 est accessible
- [ ] Le volume Oracle persiste apres redemarrage
- [ ] BRONZE existe
- [ ] SILVER existe
- [ ] GOLD existe
- [ ] PIPELINE existe
- [ ] SYSTEM reste reserve a l'administration
- [ ] Les connexions SQL Developer fonctionnent
- [ ] `SELECT USER FROM dual` retourne le bon utilisateur

Une fois cette checklist validee, l'etape 1 est terminee et le projet peut passer au chargement des donnees Olist.
