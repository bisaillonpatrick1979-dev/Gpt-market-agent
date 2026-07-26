import Link from "next/link";

const links = [
  ["/salle", "Salle des marchés"],
  ["/cycles", "Cycles"],
  ["/journal", "Journal"],
  ["/backtest", "Backtest"],
  ["/agents", "Agents"],
  ["/reglages", "Réglages"],
  ["/couts", "Coûts"]
] as const;

export function Navigation() {
  return (
    <nav aria-label="Navigation principale" className="flex gap-2 overflow-x-auto pb-1 lg:flex-col lg:overflow-visible">
      {links.map(([href, label]) => (
        <Link key={href} href={href} className="focus-ring min-h-11 shrink-0 rounded-lg border border-transparent px-3 py-2.5 text-sm text-[var(--texte-faible)] hover:border-[var(--bordure)] hover:bg-[var(--panneau-2)] hover:text-[var(--texte)]">
          {label}
        </Link>
      ))}
    </nav>
  );
}
