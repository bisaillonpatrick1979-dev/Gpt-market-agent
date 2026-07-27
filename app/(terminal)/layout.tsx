import { Navigation } from "@/components/navigation";

export default function TerminalLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <div className="min-h-screen">
      <header className="sticky top-0 z-20 border-b border-[var(--bordure)] bg-[color:rgba(8,11,16,0.94)] backdrop-blur">
        <div className="mx-auto flex min-h-16 max-w-[1800px] items-center justify-between gap-4 px-4 sm:px-6">
          <div>
            <p className="mono text-sm font-bold">GPT MARKET AGENT</p>
            <p className="text-xs text-[var(--texte-faible)]">PAPIER_AUTONOME · Phase 0</p>
          </div>
          <p className="rounded-lg border border-[var(--bordure)] px-3 py-2 text-xs text-[var(--texte-faible)]">
            Accès direct · utilisateur unique
          </p>
        </div>
      </header>
      <div className="mx-auto grid max-w-[1800px] gap-5 px-4 py-5 sm:px-6 lg:grid-cols-[220px_minmax(0,1fr)]">
        <aside className="panel p-2 lg:sticky lg:top-20 lg:h-[calc(100vh-6rem)]">
          <Navigation />
          <div className="mt-4 hidden border-t border-[var(--bordure)] p-3 text-xs leading-5 text-[var(--texte-faible)] lg:block">
            Résultats simulés. Risque de perte totale du capital.
          </div>
        </aside>
        <main className="min-w-0">{children}</main>
      </div>
    </div>
  );
}
