"use server";

import { headers } from "next/headers";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";

function isEmailRateLimit(error: { status?: number; code?: string; message?: string }) {
  const message = error.message?.toLowerCase() ?? "";
  return (
    error.status === 429 ||
    error.code === "over_email_send_rate_limit" ||
    message.includes("rate limit") ||
    message.includes("only request this after")
  );
}

export async function sendMagicLink(formData: FormData) {
  const emailValue = formData.get("email");
  if (typeof emailValue !== "string" || !emailValue.includes("@")) {
    redirect("/connexion?erreur=courriel");
  }

  const requestHeaders = await headers();
  const origin = requestHeaders.get("origin") ?? process.env.APP_URL ?? "http://localhost:3000";
  const supabase = await createClient();
  const { error } = await supabase.auth.signInWithOtp({
    email: emailValue.trim().toLowerCase(),
    options: { emailRedirectTo: `${origin}/auth/callback` }
  });

  if (error) {
    if (isEmailRateLimit(error)) {
      redirect("/connexion?erreur=limite");
    }
    redirect("/connexion?erreur=envoi");
  }

  redirect("/connexion?envoye=1");
}
