-- Phase 0 : index, RLS, initialisation de firme, audit immuable et Realtime.

create index profils_role_idx on public.profils(role);
create index fournisseurs_proprietaire_idx on public.fournisseurs_donnees(proprietaire_id);
create index quotas_fournisseur_fenetre_idx on public.quotas_fournisseurs(fournisseur_id, fin_fenetre desc);
create index symboles_proprietaire_actif_idx on public.symboles(proprietaire_id, classe_actif, actif);
create index chandeliers_recherche_idx on public.chandeliers(proprietaire_id, symbole_id, intervalle, horodatage desc);
create index agents_proprietaire_ordre_idx on public.agents(proprietaire_id, ordre_organigramme);
create unique index mandats_un_actif_par_agent_idx on public.mandats_agents(agent_id) where actif;
create index cycles_recherche_idx on public.cycles(proprietaire_id, commence_le desc, etat);
create index transitions_cycle_idx on public.transitions_cycles(cycle_id, cree_le);
create index messages_cycle_sequence_idx on public.messages_agents(cycle_id, sequence);
create index rapports_cycle_idx on public.rapports_analyse(cycle_id, agent_id);
create index propositions_statut_idx on public.propositions_ordres(proprietaire_id, statut, cree_le desc);
create index ordres_portefeuille_statut_idx on public.ordres(portefeuille_id, statut, cree_le desc);
create index positions_ouvertes_idx on public.positions(portefeuille_id, statut) where statut = 'ouverte';
create index transactions_portefeuille_idx on public.transactions(portefeuille_id, cree_le desc);
create index instantanes_portefeuille_date_idx on public.instantanes_portefeuille(portefeuille_id, date_snapshot desc);
create index appels_llm_cout_idx on public.appels_llm(proprietaire_id, cree_le desc, agent_id);
create index backtests_proprietaire_idx on public.backtests(proprietaire_id, cree_le desc);
create index evenements_macro_horodatage_idx on public.evenements_macro(proprietaire_id, horodatage, impact);
create index journal_audit_proprietaire_idx on public.journal_audit(proprietaire_id, cree_le desc);
create index lecons_embedding_hnsw_idx on public.lecons using hnsw (embedding extensions.vector_cosine_ops) where embedding is not null;

-- Les colonnes utilisées par RLS sont toutes indexées.
do $$
declare
  nom_table text;
begin
  foreach nom_table in array array[
    'parametres_firme','configurations_risque','fournisseurs_donnees','cles_api','quotas_fournisseurs',
    'symboles','correspondances_symboles','chandeliers','agents','mandats_agents','portefeuilles','cycles',
    'transitions_cycles','messages_agents','rapports_analyse','propositions_ordres','decisions_risque','ordres',
    'positions','transactions','instantanes_portefeuille','lecons','appels_llm','backtests','evenements_macro','journal_audit'
  ]
  loop
    execute format('create index if not exists %I on public.%I (proprietaire_id)', nom_table || '_proprietaire_rls_idx', nom_table);
  end loop;
end $$;

-- Mise à jour uniforme des horodatages.
create or replace function app_prive.appliquer_modification()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  new.modifie_le = now();
  return new;
end;
$$;
revoke all on function app_prive.appliquer_modification() from public, anon, authenticated;

do $$
declare
  nom_table text;
begin
  foreach nom_table in array array[
    'profils','parametres_firme','configurations_risque','fournisseurs_donnees','cles_api','symboles',
    'agents','propositions_ordres','ordres','portefeuilles','cycles'
  ]
  loop
    execute format('create trigger %I before update on public.%I for each row execute function app_prive.appliquer_modification()', 'maj_' || nom_table, nom_table);
  end loop;
end $$;

-- Création atomique de la firme et de ses 12 spécialistes après la première authentification.
create or replace function app_prive.initialiser_nouvel_utilisateur()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  portefeuille_uuid uuid;
  agent_uuid uuid;
  item record;
begin
  insert into public.profils (id, courriel, nom_affichage)
  values (new.id, coalesce(new.email, ''), coalesce(new.raw_user_meta_data ->> 'full_name', split_part(coalesce(new.email, 'Propriétaire'), '@', 1)));

  insert into public.parametres_firme (proprietaire_id) values (new.id);
  insert into public.configurations_risque (proprietaire_id) values (new.id);

  insert into public.portefeuilles (proprietaire_id)
  values (new.id)
  returning id into portefeuille_uuid;

  insert into public.fournisseurs_donnees (proprietaire_id, code, nom, actif, etat, limite_quota, fenetre_quota_secondes)
  values
    (new.id, 'mock', 'Mock déterministe', true, 'connecte', null, null),
    (new.id, 'yahoo', 'Yahoo Finance', false, 'non_configure', null, null),
    (new.id, 'twelvedata', 'Twelve Data', false, 'non_configure', 800, 86400),
    (new.id, 'finnhub', 'Finnhub', false, 'non_configure', 60, 60),
    (new.id, 'alphavantage', 'Alpha Vantage', false, 'non_configure', 25, 86400),
    (new.id, 'alpaca', 'Alpaca Paper', false, 'non_configure', null, null);

  for item in
    select * from (values
      ('Analyste technique', 'analyste_technique'::public.categorie_agent, 'Analyse technique', 10,
       'Analyse uniquement le snapshot fourni. Cite des niveaux chiffrés présents dans les données et refuse toute valeur absente.'),
      ('Analyste macro / Forex', 'analyste_macro_forex'::public.categorie_agent, 'Macroéconomie et devises', 20,
       'Analyse le calendrier économique, les banques centrales, les taux, le DXY et les sessions pour les paires de devises.'),
      ('Analyste fondamental', 'analyste_fondamental'::public.categorie_agent, 'Fondamentaux actions et indices', 30,
       'Analyse résultats, valorisations, secteurs et composition des indices sans extrapoler au-delà des sources fournies.'),
      ('Analyste sentiment & nouvelles', 'analyste_sentiment_nouvelles'::public.categorie_agent, 'Nouvelles et sentiment', 40,
       'Résume le ton du marché et les événements à risque avec source et horodatage pour chaque fait externe.'),
      ('Analyste volatilité & liquidité', 'analyste_volatilite_liquidite'::public.categorie_agent, 'Volatilité et liquidité', 50,
       'Mesure ATR, spreads, liquidité et événements; peut recommander explicitement de ne pas trader.'),
      ('Chercheur haussier', 'chercheur_haussier'::public.categorie_agent, 'Thèse haussière', 60,
       'Construit la meilleure thèse haussière possible à partir des rapports vérifiés, sans inventer de donnée.'),
      ('Chercheur baissier', 'chercheur_baissier'::public.categorie_agent, 'Thèse baissière', 70,
       'Construit la thèse inverse et attaque précisément les hypothèses fragiles de la thèse haussière.'),
      ('Directeur de recherche', 'directeur_recherche'::public.categorie_agent, 'Arbitrage de recherche', 80,
       'Arbitre les arguments selon leur solidité et produit direction, conviction, horizon et invalidation.'),
      ('Trader', 'trader'::public.categorie_agent, 'Construction d’ordre', 90,
       'Traduit la synthèse en proposition structurée et refuse toute proposition sans stop-loss.'),
      ('Gestionnaire de risque', 'gestionnaire_risque'::public.categorie_agent, 'Contrôle indépendant', 100,
       'Applique les contraintes calculées par le moteur de risque. Il peut réduire la taille ou opposer son veto.'),
      ('Gestionnaire de portefeuille', 'gestionnaire_portefeuille'::public.categorie_agent, 'Décision finale papier', 110,
       'Décide après contrôle de risque. Il est le seul agent autorisé à demander la soumission d’un ordre papier.'),
      ('Agent de réflexion', 'agent_reflexion'::public.categorie_agent, 'Post-mortem et mémoire', 120,
       'Après fermeture, compare la thèse, l’exécution et le résultat puis écrit une leçon réutilisable.' )
    ) as t(nom, categorie, role_affiche, ordre_organigramme, mandat)
  loop
    insert into public.agents (
      proprietaire_id, nom, categorie, role_affiche, fournisseur_llm, modele, temperature, ordre_organigramme
    ) values (
      new.id, item.nom, item.categorie, item.role_affiche, 'mock', 'mock-deterministe-v1', 0, item.ordre_organigramme
    ) returning id into agent_uuid;

    insert into public.mandats_agents (proprietaire_id, agent_id, version, mandat, actif, cree_par)
    values (new.id, agent_uuid, 1, item.mandat, true, new.id);
  end loop;

  return new;
end;
$$;
revoke all on function app_prive.initialiser_nouvel_utilisateur() from public, anon, authenticated;

drop trigger if exists apres_creation_utilisateur on auth.users;
create trigger apres_creation_utilisateur
after insert on auth.users
for each row execute function app_prive.initialiser_nouvel_utilisateur();

-- Le kill switch annule l’attente et gèle la comptabilité sans dépendre du client.
create or replace function app_prive.appliquer_kill_switch()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.kill_switch_active = true and old.kill_switch_active = false then
    update public.ordres
      set statut = 'annule', raison_rejet = 'Kill switch activé', modifie_le = now()
      where proprietaire_id = new.proprietaire_id
        and statut in ('propose', 'attente_validation', 'approuve', 'soumis', 'partiel');

    update public.portefeuilles
      set gele = true, modifie_le = now()
      where proprietaire_id = new.proprietaire_id;

    update public.agents
      set statut = 'arrete', modifie_le = now()
      where proprietaire_id = new.proprietaire_id and statut <> 'inactif';
  end if;
  return new;
end;
$$;
revoke all on function app_prive.appliquer_kill_switch() from public, anon, authenticated;

create trigger declencher_kill_switch
after update of kill_switch_active on public.parametres_firme
for each row execute function app_prive.appliquer_kill_switch();

-- Journal immuable : même une erreur applicative ne peut pas réécrire l’histoire.
create or replace function app_prive.refuser_mutation_audit()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  raise exception 'Le journal d’audit est immuable';
end;
$$;
revoke all on function app_prive.refuser_mutation_audit() from public, anon, authenticated;

create trigger journal_audit_immuable
before update or delete on public.journal_audit
for each row execute function app_prive.refuser_mutation_audit();

-- Activation RLS sur toute table exposée.
do $$
declare
  nom_table text;
begin
  foreach nom_table in array array[
    'profils','parametres_firme','configurations_risque','fournisseurs_donnees','cles_api','quotas_fournisseurs',
    'symboles','correspondances_symboles','chandeliers','agents','mandats_agents','portefeuilles','cycles',
    'transitions_cycles','messages_agents','rapports_analyse','propositions_ordres','decisions_risque','ordres',
    'positions','transactions','instantanes_portefeuille','lecons','appels_llm','backtests','evenements_macro','journal_audit'
  ]
  loop
    execute format('alter table public.%I enable row level security', nom_table);
  end loop;
end $$;

-- Privilèges minimaux. Les secrets n’ont aucun droit client.
revoke all on all tables in schema public from anon;
revoke all on public.cles_api from authenticated;
grant select, update on public.profils to authenticated;
grant select, update on public.parametres_firme to authenticated;
grant select, update on public.configurations_risque to authenticated;
grant select, insert, update, delete on public.fournisseurs_donnees to authenticated;
grant select, insert, update, delete on public.symboles to authenticated;
grant select, insert, update, delete on public.correspondances_symboles to authenticated;
grant select, update on public.agents to authenticated;
grant select, insert, update on public.mandats_agents to authenticated;
grant select on public.quotas_fournisseurs, public.chandeliers, public.portefeuilles, public.cycles,
  public.transitions_cycles, public.messages_agents, public.rapports_analyse, public.propositions_ordres,
  public.decisions_risque, public.ordres, public.positions, public.transactions, public.instantanes_portefeuille,
  public.lecons, public.appels_llm, public.backtests, public.evenements_macro, public.journal_audit to authenticated;
grant usage, select on all sequences in schema public to authenticated;

-- Profil : l’identifiant de ligne est l’utilisateur Supabase.
create policy profils_lecture_propre on public.profils for select to authenticated
using ((select auth.uid()) = id);
create policy profils_modification_propre on public.profils for update to authenticated
using ((select auth.uid()) = id) with check ((select auth.uid()) = id);

-- Tables modifiables par le propriétaire.
do $$
declare
  nom_table text;
begin
  foreach nom_table in array array[
    'parametres_firme','configurations_risque','fournisseurs_donnees','symboles','correspondances_symboles','agents','mandats_agents'
  ]
  loop
    execute format('create policy %I on public.%I for select to authenticated using ((select auth.uid()) = proprietaire_id)', nom_table || '_lecture_propre', nom_table);
    execute format('create policy %I on public.%I for insert to authenticated with check ((select auth.uid()) = proprietaire_id)', nom_table || '_creation_propre', nom_table);
    execute format('create policy %I on public.%I for update to authenticated using ((select auth.uid()) = proprietaire_id) with check ((select auth.uid()) = proprietaire_id)', nom_table || '_modification_propre', nom_table);
    execute format('create policy %I on public.%I for delete to authenticated using ((select auth.uid()) = proprietaire_id)', nom_table || '_suppression_propre', nom_table);
  end loop;
end $$;

-- Tables métier en lecture client; les écritures passent par le serveur.
do $$
declare
  nom_table text;
begin
  foreach nom_table in array array[
    'quotas_fournisseurs','chandeliers','portefeuilles','cycles','transitions_cycles','messages_agents','rapports_analyse',
    'propositions_ordres','decisions_risque','ordres','positions','transactions','instantanes_portefeuille','lecons',
    'appels_llm','backtests','evenements_macro','journal_audit'
  ]
  loop
    execute format('create policy %I on public.%I for select to authenticated using ((select auth.uid()) = proprietaire_id)', nom_table || '_lecture_propre', nom_table);
  end loop;
end $$;

-- Aucune politique pour cles_api : inaccessible avec la clé publique, même authentifié.

-- Realtime limité aux flux nécessaires à la salle des marchés.
do $$
declare
  nom_table text;
begin
  foreach nom_table in array array['cycles','messages_agents','ordres','positions','portefeuilles']
  loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = nom_table
    ) then
      execute format('alter publication supabase_realtime add table public.%I', nom_table);
    end if;
  end loop;
end $$;
