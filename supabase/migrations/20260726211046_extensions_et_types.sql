-- Phase 0 : extensions et types partagés.
create extension if not exists vector with schema extensions;

create schema if not exists app_prive;
revoke all on schema app_prive from public, anon, authenticated;

create type public.role_profil as enum ('proprietaire', 'administrateur', 'observateur');
create type public.mode_operation as enum ('PAPIER_AUTONOME', 'PAPIER_VALIDATION', 'REEL_VALIDATION');
create type public.statut_agent as enum ('actif', 'inactif', 'pause_cout', 'arrete');
create type public.categorie_agent as enum (
  'analyste_technique',
  'analyste_macro_forex',
  'analyste_fondamental',
  'analyste_sentiment_nouvelles',
  'analyste_volatilite_liquidite',
  'chercheur_haussier',
  'chercheur_baissier',
  'directeur_recherche',
  'trader',
  'gestionnaire_risque',
  'gestionnaire_portefeuille',
  'agent_reflexion'
);
create type public.classe_actif as enum ('forex', 'indice', 'action', 'crypto', 'etf');
create type public.intervalle_marche as enum ('M1', 'M5', 'M15', 'M30', 'H1', 'H4', 'D1');
create type public.etat_cycle as enum (
  'COLLECTE_DONNEES',
  'ANALYSE',
  'DEBAT',
  'SYNTHESE',
  'PROPOSITION',
  'CONTROLE_RISQUE',
  'DECISION_PM',
  'EXECUTION',
  'JOURNALISATION',
  'TERMINE',
  'ECHOUE',
  'ABANDONNE'
);
create type public.declencheur_cycle as enum ('manuel', 'planifie', 'evenement_prix');
create type public.sens_ordre as enum ('achat', 'vente');
create type public.type_ordre as enum ('marche', 'limite', 'stop');
create type public.statut_ordre as enum ('propose', 'attente_validation', 'approuve', 'refuse', 'soumis', 'partiel', 'execute', 'annule', 'expire', 'rejete');
create type public.decision_risque_type as enum ('approuve', 'taille_reduite', 'rejete');
create type public.statut_position as enum ('ouverte', 'fermee', 'liquidee');
create type public.statut_backtest as enum ('brouillon', 'en_attente', 'en_cours', 'termine', 'echoue', 'annule');
create type public.type_message_agent as enum ('analyse', 'argument', 'synthese', 'proposition', 'veto', 'decision', 'reflexion', 'systeme');
create type public.etat_fournisseur as enum ('non_configure', 'connecte', 'degrade', 'quota_epuise', 'erreur', 'desactive');
