/**
 * Point d’entrée des types de base. Le type complet est régénéré depuis Supabase
 * après chaque migration avant d’implémenter un domaine qui écrit dans la base.
 */
export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[];

export type ModeOperation = "PAPIER_AUTONOME" | "PAPIER_VALIDATION" | "REEL_VALIDATION";
export type CycleState =
  | "COLLECTE_DONNEES"
  | "ANALYSE"
  | "DEBAT"
  | "SYNTHESE"
  | "PROPOSITION"
  | "CONTROLE_RISQUE"
  | "DECISION_PM"
  | "EXECUTION"
  | "JOURNALISATION"
  | "TERMINE"
  | "ECHOUE"
  | "ABANDONNE";
