-- Ajustements issus des conseillers Supabase après la première migration.
drop index if exists public.fournisseurs_proprietaire_idx;

create index if not exists appels_llm_agent_id_idx on public.appels_llm(agent_id);
create index if not exists appels_llm_cycle_id_idx on public.appels_llm(cycle_id);
create index if not exists backtests_symbole_id_idx on public.backtests(symbole_id);
create index if not exists chandeliers_symbole_id_idx on public.chandeliers(symbole_id);
create index if not exists cles_api_fournisseur_id_idx on public.cles_api(fournisseur_id);
create index if not exists correspondances_symboles_symbole_id_idx on public.correspondances_symboles(symbole_id);
create index if not exists cycles_portefeuille_id_idx on public.cycles(portefeuille_id);
create index if not exists cycles_symbole_id_idx on public.cycles(symbole_id);
create index if not exists decisions_risque_agent_id_idx on public.decisions_risque(agent_risque_id);
create index if not exists decisions_risque_proposition_id_idx on public.decisions_risque(proposition_id);
create index if not exists lecons_cycle_id_idx on public.lecons(cycle_id);
create index if not exists lecons_position_id_idx on public.lecons(position_id);
create index if not exists lecons_symbole_id_idx on public.lecons(symbole_id);
create index if not exists mandats_agents_cree_par_idx on public.mandats_agents(cree_par);
create index if not exists messages_agents_agent_id_idx on public.messages_agents(agent_id);
create index if not exists ordres_cycle_id_idx on public.ordres(cycle_id);
create index if not exists ordres_proposition_id_idx on public.ordres(proposition_id);
create index if not exists ordres_symbole_id_idx on public.ordres(symbole_id);
create index if not exists positions_ordre_ouverture_id_idx on public.positions(ordre_ouverture_id);
create index if not exists positions_symbole_id_idx on public.positions(symbole_id);
create index if not exists propositions_ordres_agent_id_idx on public.propositions_ordres(agent_trader_id);
create index if not exists propositions_ordres_cycle_id_idx on public.propositions_ordres(cycle_id);
create index if not exists propositions_ordres_portefeuille_id_idx on public.propositions_ordres(portefeuille_id);
create index if not exists propositions_ordres_symbole_id_idx on public.propositions_ordres(symbole_id);
create index if not exists rapports_analyse_agent_id_idx on public.rapports_analyse(agent_id);
create index if not exists transactions_ordre_id_idx on public.transactions(ordre_id);
create index if not exists transactions_position_id_idx on public.transactions(position_id);
create index if not exists transactions_symbole_id_idx on public.transactions(symbole_id);

create policy cles_api_acces_client_interdit
on public.cles_api
as restrictive
for all
to authenticated
using (false)
with check (false);
