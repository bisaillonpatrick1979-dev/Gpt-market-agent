type StatusCardProps = { label: string; value: string; detail: string };
export function StatusCard({ label, value, detail }: StatusCardProps) {
  return (
    <article className="panel p-4">
      <p className="text-xs uppercase tracking-wider text-[var(--texte-faible)]">{label}</p>
      <p className="mono mt-3 text-2xl font-semibold">{value}</p>
      <p className="mt-2 text-xs text-[var(--texte-faible)]">{detail}</p>
    </article>
  );
}
