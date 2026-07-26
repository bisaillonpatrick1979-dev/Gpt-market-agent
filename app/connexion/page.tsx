import { sendMagicLink } from "./actions";

type LoginPageProps = {
  searchParams: Promise<{ envoye?: string; erreur?: string }>;
};

export default async function LoginPage({ searchParams }: LoginPageProps) {
  const params = await searchParams;
  return (
    <main className="min-h-screen grid place-items-center p-5">
      <section className="panel w-full max-w-md p-6 sm:p-8">
        <p className="mono text-xs tracking-[0.2em] text-[var(--accent)]">TRADING FLOOR IA</p>
        <h1 className="mt-3 text-3xl font-semibold">GPT Market Agent</h1>
        <p className="mt-3 text-base leading-7 text-[var(--texte-faible)]">
          Connexion sécurisée par lien à usage unique. Aucun mot de passe n’est stocké par l’application.
        </p>
        {params.envoye === "1" && (
          <p className="mt-5 rounded-lg border border-[var(--bordure)] bg-[var(--panneau-2)] p-4 text-sm">
            Le lien de connexion a été envoyé. Vérifiez votre boîte de réception.
          </p>
        )}
        {params.erreur && (
          <p className="mt-5 rounded-lg border border-[var(--attention)] p-4 text-sm text-[var(--attention)]">
            Impossible d’envoyer le lien. Vérifiez le courriel et réessayez.
          </p>
        )}
        <form action={sendMagicLink} className="mt-7 space-y-4">
          <label className="block text-sm font-medium" htmlFor="email">Adresse courriel</label>
          <input
            className="focus-ring min-h-12 w-full rounded-lg border border-[var(--bordure)] bg-[var(--fond)] px-4 text-base"
            id="email"
            name="email"
            type="email"
            autoComplete="email"
            required
            placeholder="vous@exemple.ca"
          />
          <button className="focus-ring min-h-12 w-full rounded-lg bg-[var(--accent)] px-5 font-semibold text-slate-950" type="submit">
            Envoyer le lien sécurisé
          </button>
        </form>
        <p className="mt-6 text-xs leading-5 text-[var(--texte-faible)]">
          Résultats simulés. Le trading comporte un risque de perte totale du capital.
        </p>
      </section>
    </main>
  );
}
