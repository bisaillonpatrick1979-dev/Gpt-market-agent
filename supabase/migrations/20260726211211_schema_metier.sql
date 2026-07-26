-- Phase 0 : schéma métier complet. Les phases suivantes ajoutent la logique, pas une deuxième source de vérité.

create table public.profils (
  id uuid primary key references auth.users(id) on delete cascade,
  courriel text not null,
  nom_affichage text,
  role public.role_profil not null default 'proprietaire',
  fuseau_horaire text not null default 'America/Edmonton',
  devise text not null default 'CAD' check (char_length(devise) = 3),
  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now()
);

create table public.parametres_firme (
  proprietaire_id uuid primary key references public.profils(id) on delete cascade,
  mode_operation public.mode_operation not null default 'PAPIER_AUTONOME',
  kill_switch_active boolean not null default false,
  agents_geles boolean not null default false,
  tours_debat integer not null default 2 check (tours_debat between 1 and 6),
  budget_appels_cycle integer not null default 24 check (budget_appels_cycle between 1 and 100),
  budget_secondes_cycle integer not null default 180 check (budget_secondes_cycle between 15 and 1800),
  plafond_cout_quotidien_cad numeric(12,2) not null default 10 check (plafond_cout_quotidien_cad >= 0),
  trading_reel_active boolean not null default false,
  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now(),
  constraint trading_reel_bloque_phase_0 check (
    trading_reel_active = false and mode_operation <> 'REEL_VALIDATION'
  )
);

create table public.configurations_risque (
  proprietaire_id uuid primary key references public.profils(id) on delete cascade,
  risque_max_trade_pct numeric(5,2) not null default 1 check (risque_max_trade_pct > 0 and risque_max_trade_pct <= 5),
  risque_total_pct numeric(5,2) not null default 5 check (risque_total_pct > 0 and risque_total_pct <= 20),
  positions_max integer not null default 5 check (positions_max between 1 and 20),
  positions_correlees_max integer not null default 2 check (positions_correlees_max between 1 and 10),
  perte_journaliere_max_pct numeric(5,2) not null default 3 check (perte_journaliere_max_pct > 0 and perte_journaliere_max_pct <= 10),
  drawdown_max_pct numeric(5,2) not null default 15 check (drawdown_max_pct > 0 and drawdown_max_pct <= 50),
  levier_max numeric(6,2) not null default 10 check (levier_max >= 1 and levier_max <= 10),
  fenetre_macro_minutes integer not null default 30 check (fenetre_macro_minutes between 0 and 180),
  exige_stop_loss boolean not null default true,
  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now()
);

create table public.fournisseurs_donnees (
  id uuid primary key default gen_random_uuid(),
  proprietaire_id uuid not null references public.profils(id) on delete cascade,
  code text not null check (code in ('yahoo', 'twelvedata', 'finnhub', 'alphavantage', 'alpaca', 'mock')),
  nom text not null,
  actif boolean not null default false,
  etat public.etat_fournisseur not null default 'non_configure',
  priorites_par_actif jsonb not null default '{}'::jsonb,
  limite_quota integer,
  fenetre_quota_secondes integer,
  derniere_verification_le timestamptz,
  derniere_erreur text,
  configuration jsonb not null default '{}'::jsonb,
  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now(),
  unique (proprietaire_id, code)
);

create table public.cles_api (
  id uuid primary key default gen_random_uuid(),
  proprietaire_id uuid not null references public.profils(id) on delete cascade,
  fournisseur_id uuid not null references public.fournisseurs_donnees(id) on delete cascade,
  nom_cle text not null,
  secret_chiffre bytea not null,
  nonce bytea not null,
  algorithme text not null default 'AES-256-GCM',
  version_cle integer not null default 1,
  quatre_derniers text,
  active boolean not null default true,
  derniere_rotation_le timestamptz,
  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now(),
  unique (proprietaire_id, fournisseur_id, nom_cle)
);

create table public.quotas_fournisseurs (
  id uuid primary key default gen_random_uuid(),
  proprietaire_id uuid not null references public.profils(id) on delete cascade,
  fournisseur_id uuid not null references public.fournisseurs_donnees(id) on delete cascade,
  debut_fenetre timestamptz not null,
  fin_fenetre timestamptz not null,
  appels_utilises integer not null default 0 check (appels_utilises >= 0),
  limite_appels integer not null check (limite_appels >= 0),
  modifie_le timestamptz not null default now(),
  unique (fournisseur_id, debut_fenetre)
);

create table public.symboles (
  id uuid primary key default gen_random_uuid(),
  proprietaire_id uuid not null references public.profils(id) on delete cascade,
  symbole_canonique text not null,
  nom text not null,
  classe_actif public.classe_actif not null,
  devise_cotation text check (devise_cotation is null or char_length(devise_cotation) = 3),
  place_marche text,
  fuseau_horaire text not null default 'UTC',
  taille_tick numeric(20,10),
  taille_contrat numeric(20,6),
  spread_fixe numeric(20,10),
  levier_max_instrument numeric(8,2),
  heures_seance jsonb not null default '{}'::jsonb,
  actif boolean not null default true,
  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now(),
  unique (proprietaire_id, symbole_canonique)
);

create table public.correspondances_symboles (
  id uuid primary key default gen_random_uuid(),
  proprietaire_id uuid not null references public.profils(id) on delete cascade,
  symbole_id uuid not null references public.symboles(id) on delete cascade,
  fournisseur_code text not null,
  symbole_fournisseur text not null,
  configuration jsonb not null default '{}'::jsonb,
  unique (proprietaire_id, symbole_id, fournisseur_code)
);

create table public.chandeliers (
  id bigint generated always as identity primary key,
  proprietaire_id uuid not null references public.profils(id) on delete cascade,
  symbole_id uuid not null references public.symboles(id) on delete cascade,
  intervalle public.intervalle_marche not null,
  horodatage bigint not null check (horodatage > 0),
  ouverture numeric(24,10) not null,
  haut numeric(24,10) not null,
  bas numeric(24,10) not null,
  fermeture numeric(24,10) not null,
  volume numeric(28,8),
  fournisseur_code text not null,
  bougie_fermee boolean not null default true,
  perime boolean not null default false,
  recu_le timestamptz not null default now(),
  expires_le timestamptz,
  constraint ohlc_coherent check (haut >= greatest(ouverture, fermeture, bas) and bas <= least(ouverture, fermeture, haut)),
  unique (proprietaire_id, symbole_id, intervalle, horodatage)
);

create table public.agents (
  id uuid primary key default gen_random_uuid(),
  proprietaire_id uuid not null references public.profils(id) on delete cascade,
  nom text not null,
  categorie public.categorie_agent not null,
  role_affiche text not null,
  description text,
  fournisseur_llm text not null default 'mock' check (fournisseur_llm in ('openai', 'anthropic', 'google', 'mock')),
  modele text not null default 'mock-deterministe-v1',
  temperature numeric(4,3) not null default 0 check (temperature >= 0 and temperature <= 2),
  outils_autorises text[] not null default '{}'::text[],
  statut public.statut_agent not null default 'actif',
  ordre_organigramme integer not null,
  couleur_ui text,
  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now(),
  unique (proprietaire_id, categorie)
);

create table public.mandats_agents (
  id uuid primary key default gen_random_uuid(),
  proprietaire_id uuid not null references public.profils(id) on delete cascade,
  agent_id uuid not null references public.agents(id) on delete cascade,
  version integer not null check (version > 0),
  mandat text not null,
  actif boolean not null default true,
  cree_par uuid references public.profils(id) on delete set null,
  cree_le timestamptz not null default now(),
  unique (agent_id, version)
);

create table public.portefeuilles (
  id uuid primary key default gen_random_uuid(),
  proprietaire_id uuid not null references public.profils(id) on delete cascade,
  nom text not null default 'Portefeuille papier principal',
  devise text not null default 'CAD' check (char_length(devise) = 3),
  capital_initial numeric(20,2) not null default 100000 check (capital_initial >= 0),
  solde_liquide numeric(20,2) not null default 100000,
  valeur_totale numeric(20,2) not null default 100000,
  valeur_sommet numeric(20,2) not null default 100000,
  pnl_realise numeric(20,2) not null default 0,
  pnl_non_realise numeric(20,2) not null default 0,
  perte_journaliere numeric(20,2) not null default 0,
  marge_utilisee numeric(20,2) not null default 0,
  gele boolean not null default false,
  ferme boolean not null default false,
  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now(),
  unique (proprietaire_id, nom)
);

create table public.cycles (
  id uuid primary key default gen_random_uuid(),
  proprietaire_id uuid not null references public.profils(id) on delete cascade,
  portefeuille_id uuid not null references public.portefeuilles(id) on delete cascade,
  symbole_id uuid not null references public.symboles(id) on delete restrict,
  intervalle public.intervalle_marche not null,
  declencheur public.declencheur_cycle not null,
  etat public.etat_cycle not null default 'COLLECTE_DONNEES',
  tour_debat_courant integer not null default 0,
  appels_llm_utilises integer not null default 0,
  budget_appels integer not null,
  budget_secondes integer not null,
  snapshot_marche jsonb,
  contexte_portefeuille jsonb,
  erreur_code text,
  erreur_message text,
  reprenable boolean not null default true,
  commence_le timestamptz not null default now(),
  modifie_le timestamptz not null default now(),
  termine_le timestamptz
);

create table public.transitions_cycles (
  id bigint generated always as identity primary key,
  proprietaire_id uuid not null references public.profils(id) on delete cascade,
  cycle_id uuid not null references public.cycles(id) on delete cascade,
  etat_source public.etat_cycle,
  etat_cible public.etat_cycle not null,
  raison text,
  donnees jsonb not null default '{}'::jsonb,
  cree_le timestamptz not null default now()
);

create table public.messages_agents (
  id uuid primary key default gen_random_uuid(),
  proprietaire_id uuid not null references public.profils(id) on delete cascade,
  cycle_id uuid not null references public.cycles(id) on delete cascade,
  agent_id uuid references public.agents(id) on delete set null,
  sequence integer not null check (sequence >= 0),
  tour_debat integer,
  type_message public.type_message_agent not null,
  contenu text not null,
  contenu_structure jsonb,
  raisonnement_resume text,
  final boolean not null default true,
  cree_le timestamptz not null default now(),
  unique (cycle_id, sequence)
);

create table public.rapports_analyse (
  id uuid primary key default gen_random_uuid(),
  proprietaire_id uuid not null references public.profils(id) on delete cascade,
  cycle_id uuid not null references public.cycles(id) on delete cascade,
  agent_id uuid not null references public.agents(id) on delete restrict,
  type_rapport text not null,
  direction text,
  conviction integer check (conviction between 0 and 100),
  niveaux jsonb not null default '{}'::jsonb,
  sources jsonb not null default '[]'::jsonb,
  rapport jsonb not null,
  valide boolean not null default false,
  cree_le timestamptz not null default now()
);

create table public.propositions_ordres (
  id uuid primary key default gen_random_uuid(),
  proprietaire_id uuid not null references public.profils(id) on delete cascade,
  cycle_id uuid not null references public.cycles(id) on delete cascade,
  portefeuille_id uuid not null references public.portefeuilles(id) on delete cascade,
  symbole_id uuid not null references public.symboles(id) on delete restrict,
  agent_trader_id uuid not null references public.agents(id) on delete restrict,
  sens public.sens_ordre not null,
  type_ordre public.type_ordre not null,
  quantite numeric(24,8) not null check (quantite > 0),
  prix_entree numeric(24,10),
  stop_loss numeric(24,10) not null,
  take_profit numeric(24,10),
  validite_jusqua timestamptz,
  justification text not null,
  statut public.statut_ordre not null default 'propose',
  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now()
);

create table public.decisions_risque (
  id uuid primary key default gen_random_uuid(),
  proprietaire_id uuid not null references public.profils(id) on delete cascade,
  proposition_id uuid not null references public.propositions_ordres(id) on delete cascade,
  agent_risque_id uuid references public.agents(id) on delete set null,
  decision public.decision_risque_type not null,
  quantite_demandee numeric(24,8) not null,
  quantite_autorisee numeric(24,8) not null,
  risque_trade_pct numeric(7,4),
  risque_total_pct numeric(7,4),
  raisons text[] not null default '{}'::text[],
  controles jsonb not null default '{}'::jsonb,
  cree_le timestamptz not null default now()
);

create table public.ordres (
  id uuid primary key default gen_random_uuid(),
  proprietaire_id uuid not null references public.profils(id) on delete cascade,
  portefeuille_id uuid not null references public.portefeuilles(id) on delete cascade,
  proposition_id uuid references public.propositions_ordres(id) on delete set null,
  symbole_id uuid not null references public.symboles(id) on delete restrict,
  cycle_id uuid references public.cycles(id) on delete set null,
  sens public.sens_ordre not null,
  type_ordre public.type_ordre not null,
  statut public.statut_ordre not null,
  quantite_demandee numeric(24,8) not null check (quantite_demandee > 0),
  quantite_executee numeric(24,8) not null default 0 check (quantite_executee >= 0),
  prix_demande numeric(24,10),
  prix_moyen_execution numeric(24,10),
  stop_loss numeric(24,10) not null,
  take_profit numeric(24,10),
  spread_applique numeric(24,10) not null default 0,
  slippage_applique numeric(24,10) not null default 0,
  commission_estimee numeric(20,6) not null default 0,
  raison_rejet text,
  validation_utilisateur_le timestamptz,
  expire_le timestamptz,
  soumis_le timestamptz,
  execute_le timestamptz,
  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now()
);

create table public.positions (
  id uuid primary key default gen_random_uuid(),
  proprietaire_id uuid not null references public.profils(id) on delete cascade,
  portefeuille_id uuid not null references public.portefeuilles(id) on delete cascade,
  symbole_id uuid not null references public.symboles(id) on delete restrict,
  ordre_ouverture_id uuid not null references public.ordres(id) on delete restrict,
  sens public.sens_ordre not null,
  statut public.statut_position not null default 'ouverte',
  quantite numeric(24,8) not null check (quantite > 0),
  prix_entree numeric(24,10) not null,
  prix_courant numeric(24,10),
  stop_loss numeric(24,10) not null,
  take_profit numeric(24,10),
  pnl_non_realise numeric(20,2) not null default 0,
  pnl_realise numeric(20,2) not null default 0,
  marge_requise numeric(20,2) not null default 0,
  ouverte_le timestamptz not null,
  fermee_le timestamptz,
  modifie_le timestamptz not null default now()
);

create table public.transactions (
  id uuid primary key default gen_random_uuid(),
  proprietaire_id uuid not null references public.profils(id) on delete cascade,
  portefeuille_id uuid not null references public.portefeuilles(id) on delete cascade,
  ordre_id uuid not null references public.ordres(id) on delete restrict,
  position_id uuid references public.positions(id) on delete set null,
  symbole_id uuid not null references public.symboles(id) on delete restrict,
  type_transaction text not null check (type_transaction in ('ouverture', 'fermeture', 'partielle', 'commission', 'swap', 'liquidation')),
  sens public.sens_ordre,
  quantite numeric(24,8) not null,
  prix numeric(24,10),
  montant numeric(20,2) not null,
  frais numeric(20,6) not null default 0,
  pnl_realise numeric(20,2) not null default 0,
  horodatage_marche bigint,
  cree_le timestamptz not null default now()
);

create table public.instantanes_portefeuille (
  id bigint generated always as identity primary key,
  proprietaire_id uuid not null references public.profils(id) on delete cascade,
  portefeuille_id uuid not null references public.portefeuilles(id) on delete cascade,
  date_snapshot date not null,
  valeur_totale numeric(20,2) not null,
  solde_liquide numeric(20,2) not null,
  pnl_jour numeric(20,2) not null,
  pnl_cumule numeric(20,2) not null,
  drawdown_pct numeric(8,4) not null,
  exposition jsonb not null default '{}'::jsonb,
  cree_le timestamptz not null default now(),
  unique (portefeuille_id, date_snapshot)
);

create table public.lecons (
  id uuid primary key default gen_random_uuid(),
  proprietaire_id uuid not null references public.profils(id) on delete cascade,
  symbole_id uuid references public.symboles(id) on delete cascade,
  cycle_id uuid references public.cycles(id) on delete set null,
  position_id uuid references public.positions(id) on delete set null,
  titre text not null,
  contenu text not null,
  etiquettes text[] not null default '{}'::text[],
  resultat text check (resultat in ('gain', 'perte', 'neutre')),
  embedding extensions.vector(1536),
  modele_embedding text,
  cree_le timestamptz not null default now()
);

create table public.appels_llm (
  id uuid primary key default gen_random_uuid(),
  proprietaire_id uuid not null references public.profils(id) on delete cascade,
  cycle_id uuid references public.cycles(id) on delete set null,
  agent_id uuid references public.agents(id) on delete set null,
  fournisseur text not null,
  modele text not null,
  jetons_entree integer not null default 0 check (jetons_entree >= 0),
  jetons_sortie integer not null default 0 check (jetons_sortie >= 0),
  cout_estime_cad numeric(16,8) not null default 0 check (cout_estime_cad >= 0),
  latence_ms integer not null default 0 check (latence_ms >= 0),
  statut text not null check (statut in ('succes', 'erreur', 'annule', 'quota')), 
  erreur_code text,
  cree_le timestamptz not null default now()
);

create table public.backtests (
  id uuid primary key default gen_random_uuid(),
  proprietaire_id uuid not null references public.profils(id) on delete cascade,
  symbole_id uuid not null references public.symboles(id) on delete restrict,
  intervalle public.intervalle_marche not null,
  date_debut date not null,
  date_fin date not null,
  capital_initial numeric(20,2) not null check (capital_initial > 0),
  configuration_agents jsonb not null,
  configuration_risque jsonb not null,
  statut public.statut_backtest not null default 'brouillon',
  metriques jsonb,
  courbe_equite jsonb,
  comparaison_buy_hold jsonb,
  comparaison_aleatoire jsonb,
  erreur_message text,
  commence_le timestamptz,
  termine_le timestamptz,
  cree_le timestamptz not null default now(),
  constraint periode_backtest_valide check (date_fin >= date_debut)
);

create table public.evenements_macro (
  id uuid primary key default gen_random_uuid(),
  proprietaire_id uuid not null references public.profils(id) on delete cascade,
  pays text,
  devise text,
  titre text not null,
  impact text not null check (impact in ('faible', 'moyen', 'fort')),
  horodatage timestamptz not null,
  source text not null,
  source_url text,
  donnees jsonb not null default '{}'::jsonb,
  cree_le timestamptz not null default now()
);

create table public.journal_audit (
  id bigint generated always as identity primary key,
  proprietaire_id uuid not null references public.profils(id) on delete cascade,
  acteur_id uuid,
  action text not null,
  type_entite text not null,
  entite_id text,
  avant jsonb,
  apres jsonb,
  adresse_ip inet,
  user_agent text,
  correlation_id uuid,
  cree_le timestamptz not null default now()
);
