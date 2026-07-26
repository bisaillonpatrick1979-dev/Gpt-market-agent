# GPT Market Agent

Fondations de **Trading Floor IA**, une firme de trading simulée multi-agents. La Phase 0 fournit Next.js 15, TypeScript strict, Tailwind CSS, Supabase Auth, le schéma PostgreSQL, RLS, une navigation responsive et un kill switch persistant.

> Résultats simulés. Le trading comporte un risque de perte totale du capital.

## Démarrage

```bash
cp .env.example .env.local
npm install
npm run test
npm run typecheck
npm run build
npm run dev
```

## Variables nécessaires à la Phase 0

- `NEXT_PUBLIC_SUPABASE_URL` : panneau Supabase → Connect.
- `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` : panneau Supabase → Connect. Cette clé publique est conçue pour le navigateur et reste protégée par RLS.
- `APP_URL` : URL locale ou Vercel utilisée pour le retour d’authentification.

## Clés gratuites prévues pour les phases suivantes

- Twelve Data : compte développeur Twelve Data.
- Finnhub : tableau de bord API Finnhub.
- Alpha Vantage : demande de clé gratuite Alpha Vantage.
- Alpaca : compte paper trading Alpaca.
- OpenAI, Anthropic et Google AI : consoles respectives; l’adaptateur Mock demeure le défaut gratuit.
- Yahoo Finance : aucune clé, adaptateur non critique avec cache et repli obligatoire.

Aucune clé réelle ne doit être commitée. Les secrets fournisseurs seront chiffrés côté serveur avant insertion dans `cles_api`.
