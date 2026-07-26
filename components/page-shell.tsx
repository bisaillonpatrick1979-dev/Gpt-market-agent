type PageShellProps = {
  eyebrow: string;
  title: string;
  description: string;
  children?: React.ReactNode;
};

export function PageShell({ eyebrow, title, description, children }: PageShellProps) {
  return (
    <section className="space-y-5">
      <header>
        <p className="mono text-xs tracking-[0.18em] text-[var(--accent)]">{eyebrow}</p>
        <h1 className="mt-2 text-2xl font-semibold sm:text-3xl">{title}</h1>
        <p className="mt-2 max-w-3xl text-sm leading-6 text-[var(--texte-faible)] sm:text-base">{description}</p>
      </header>
      {children ?? <div className="panel min-h-72 p-5 text-sm text-[var(--texte-faible)]">Module prêt à recevoir les fonctions de sa phase.</div>}
    </section>
  );
}
