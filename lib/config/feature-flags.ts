/**
 * Le trading réel demeure impossible avant une migration explicite de Phase 7.
 * La valeur d'environnement ne peut pas l'activer à elle seule.
 */
export const featureFlags = Object.freeze({
  realTradingEnabled: false as const,
  scheduledCyclesEnabled: false,
  paidMarketDataEnabled: false
});
