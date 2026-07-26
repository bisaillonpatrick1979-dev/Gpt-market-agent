"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

export default function AuthCallbackPage() {
  const router = useRouter();
  const [message, setMessage] = useState("Validation du lien sécurisé…");

  useEffect(() => {
    let isActive = true;

    async function completeSignIn() {
      const supabase = createClient();
      const currentUrl = new URL(window.location.href);
      const fragment = new URLSearchParams(window.location.hash.slice(1));
      const code = currentUrl.searchParams.get("code");
      const accessToken = fragment.get("access_token");
      const refreshToken = fragment.get("refresh_token");
      const providerError =
        fragment.get("error_description") ?? currentUrl.searchParams.get("error_description");

      if (providerError) {
        throw new Error(providerError);
      }

      if (code) {
        const { error } = await supabase.auth.exchangeCodeForSession(code);
        if (error) throw error;
      } else if (accessToken && refreshToken) {
        const { error } = await supabase.auth.setSession({
          access_token: accessToken,
          refresh_token: refreshToken
        });
        if (error) throw error;
      } else {
        const {
          data: { session },
          error
        } = await supabase.auth.getSession();
        if (error) throw error;
        if (!session) throw new Error("Le lien ne contient plus de session valide.");
      }

      window.history.replaceState({}, document.title, "/auth/callback");
      router.replace("/salle");
      router.refresh();
    }

    completeSignIn().catch((error: unknown) => {
      if (!isActive) return;
      const detail = error instanceof Error ? error.message : "Lien invalide ou expiré.";
      setMessage(`${detail} Retour à la connexion…`);
      window.setTimeout(() => router.replace("/connexion?erreur=lien"), 1800);
    });

    return () => {
      isActive = false;
    };
  }, [router]);

  return (
    <main className="min-h-screen grid place-items-center p-5">
      <section className="panel w-full max-w-md p-6 text-center sm:p-8" aria-live="polite">
        <p className="mono text-xs tracking-[0.2em] text-[var(--accent)]">AUTHENTIFICATION</p>
        <h1 className="mt-3 text-2xl font-semibold">Connexion en cours</h1>
        <p className="mt-4 leading-7 text-[var(--texte-faible)]">{message}</p>
      </section>
    </main>
  );
}
