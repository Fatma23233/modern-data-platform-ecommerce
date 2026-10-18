-- Verification des comptes depuis un compte administrateur
SELECT username, account_status
FROM dba_users
WHERE username IN ('BRONZE', 'SILVER', 'GOLD', 'PIPELINE')
ORDER BY username;
