"use client";

import { FormEvent, useState } from "react";
import { createClient } from "@/lib/supabase/client";

function messageForError(error: unknown) {
  const details = error as { status?: unknown; code?: unknown; message?: unknown };
  const message = typeof details?.message === "string" ? details.message.toLowerCase() : "";

  if (
    details?.status === 429 ||
    details?.code === "over_email_send_rate_limit" ||
    message.includes("rate limit") ||
    message.includes("only request this after")
  ) {
    return "Trop de demandes rapprochées. Attendez environ une minute avant d’en demander un autre.";
  }

  return "Impossible d’envoyer le lien pour le moment. Réessayez dans une minute.";
}

export default function LoginPage() {
  const [email, setEmail] = useState("");
  const [isPending, setIsPending] = useState(false);
  const [sent, setSent] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setIsPending(true);
    setSent(false);
    setErrorMessage(null);

    try {
      const supabase = createClient();
      const { error } = await supabase.auth.signInWithOtp({
        email: email.trim().toLowerCase(),
        options: {
          shouldCreateUser: false,
          emailRedirectTo: `${window.location.origin}/auth/callback`
        }
      });

      if (error) throw error;
      setSent(true);
    } catch (error) {
      setErrorMessage(messageForError(error));
    } finally {
      setIsPending(false);
    }
  }

  return (
    <main className="min-h-screen grid place-items-center p-5">
      <section className="panel w-full max-w-md p-6 sm:p-8">
        <p className="mono text-xs tracking-[0.2em] text-[var(--accent)]">TRADING FLOOR IA</p>
        <h1 className="mt-3 text-3xl font-semibold">GPT Market Agent</h1>
        <p className="mt-3 text-base leading-7 text-[var(--texte-faible)]">
          Connexion sécurisée par lien à usage unique. Aucun mot de passe n’est stocké par l’application.
        </p>

        {sent && (
          <p className="mt-5 rounded-lg border border-[var(--bordure)] bg-[var(--panneau-2)] p-4 text-sm">
            Le lien a été envoyé. Ouvrez uniquement le courriel le plus récent.
          </p>
        )}

        {errorMessage && (
          <p className="mt-5 rounded-lg border border-[var(--attention)] p-4 text-sm text-[var(--attention)]">
            {errorMessage}
          </p>
        )}

        <form onSubmit={submit} className="mt-7 space-y-4">
          <label className="block text-sm font-medium" htmlFor="email">Adresse courriel</label>
          <input
            className="focus-ring min-h-12 w-full rounded-lg border border-[var(--bordure)] bg-[var(--fond)] px-4 text-base"
            id="email"
            name="email"
            type="email"
            autoComplete="email"
            required
            value={email}
            onChange={(event) => setEmail(event.target.value)}
            placeholder="vous@exemple.ca"
          />
          <button
            className="focus-ring min-h-12 w-full rounded-lg bg-[var(--accent)] px-5 font-semibold text-slate-950 disabled:opacity-60"
            type="submit"
            disabled={isPending}
          >
            {isPending ? "Envoi en cours…" : "Envoyer le lien sécurisé"}
          </button>
        </form>

        <p className="mt-6 text-xs leading-5 text-[var(--texte-faible)]">
          Résultats simulés. Le trading comporte un risque de perte totale du capital.
        </p>
      </section>
    </main>
  );
}
