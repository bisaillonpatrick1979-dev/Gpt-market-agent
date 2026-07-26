import { PageShell } from "@/components/page-shell";
import { StatusCard } from "@/components/status-card";

export default function TradingRoomPage() {
  return (
    <PageShell eyebrow="TERMINAL PRINCIPAL" title="Salle des marchés" description="Fondations sécurisées et navigation opérationnelle. Les données réelles et le graphique arrivent dans les Phases 1 et 2.">
      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatusCard label="Portefeuille papier" value="100 000,00 $ CA" detail="Capital de départ configurable" />
        <StatusCard label="Positions ouvertes" value="0" detail="Maximum prévu : 5" />
        <StatusCard label="Drawdown" value="0,00 %" detail="Arrêt complet prévu à 15 %" />
        <StatusCard label="Agents" value="12" detail="Mandats modifiables en base" />
      </div>
      <div className="mt-4 grid gap-4 xl:grid-cols-[1fr_360px]">
        <div className="panel min-h-[420px] p-5"><p className="mono text-sm">GRAPHIQUE · PHASE 2</p></div>
        <div className="panel min-h-[420px] p-5"><p className="mono text-sm">FIL DES SPÉCIALISTES · PHASE 5</p></div>
      </div>
    </PageShell>
  );
}
