# Notes d’architecture

## Phase 0 — décisions

1. **Propriété des données** : le produit démarre mono-propriétaire, mais chaque table métier porte `proprietaire_id`. Cela évite une migration risquée si des équipes sont ajoutées.
2. **Authentification** : lien magique Supabase et session PKCE en cookies. Aucun mot de passe applicatif ni jeton en `localStorage`.
3. **Secrets** : `cles_api` n’accorde aucun droit au rôle `authenticated`. Seuls les Route Handlers serveur pourront écrire ou déchiffrer les secrets avec une clé maîtresse externe.
4. **Trading réel** : bloqué deux fois — constante TypeScript immuable et contrainte PostgreSQL empêchant `REEL_VALIDATION`.
5. **Mémoire** : embeddings normalisés à 1 536 dimensions pour permettre un index HNSW commun aux fournisseurs. Un adaptateur devra convertir toute sortie vers cette dimension.
6. **Audit** : le journal refuse toute modification ou suppression, y compris par erreur applicative.

## Trois choix qui changent le plus le résultat

- Authentification : lien magique retenu; OAuth entreprise et MFA pourront être ajoutés sans modifier les tables métier.
- Fréquence des données : le temps réel gratuit varie selon l’actif; le routeur de Phase 1 devra afficher clairement le retard et les quotas.
- Déploiement des cycles : Vercel Cron convient aux déclenchements planifiés peu fréquents; les cycles longs devront être découpés et repris depuis la machine à états.

## Dettes techniques assumées

- Le chiffrement effectif des clés fournisseurs est prévu en Phase 1, car aucune clé externe n’est utilisée en Phase 0.
- Les tables sont créées maintenant, mais les écritures métier restent réservées au serveur dans les phases correspondantes.
- Le verrouillage des dépendances doit être régénéré dans un environnement ayant accès au registre npm avant toute modification de versions.

## Pièges API suivis

- Supabase 2026 : les tables SQL ne sont plus nécessairement exposées automatiquement au Data API; les GRANT sont donc explicites.
- Supabase Auth : le SMTP par défaut peut être limité; prévoir un SMTP personnalisé avant une ouverture à plusieurs utilisateurs.
- Next.js 15 : rester sur la branche Maintenance LTS et appliquer chaque correctif de sécurité.
- lightweight-charts v5 : utiliser `chart.addSeries(CandlestickSeries, options)` et la primitive de marqueurs; à implémenter en Phase 2 après vérification de la documentation officielle.
