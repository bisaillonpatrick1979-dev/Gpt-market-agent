"use client";

import { useState } from "react";

export function KillSwitch() {
  const [isPending, setIsPending] = useState(false);
  const [message, setMessage] = useState<string | null>(null);

  async function activate() {
    setIsPending(true);
    setMessage(null);
    try {
      const response = await fetch("/api/kill-switch", { method: "POST" });
      const payload = (await response.json()) as { message?: string };
      if (!response.ok) throw new Error(payload.message ?? "Échec du kill switch.");
      setMessage("Firme gelée");
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "Échec du kill switch.");
    } finally {
      setIsPending(false);
    }
  }

  return (
    <div className="flex items-center gap-2">
      <button
        type="button"
        onClick={activate}
        disabled={isPending}
        className="focus-ring min-h-11 rounded-lg border border-[var(--attention)] px-4 text-sm font-bold text-[var(--attention)] disabled:opacity-50"
      >
        {isPending ? "Arrêt…" : "KILL SWITCH"}
      </button>
      {message && <span className="hidden text-xs text-[var(--texte-faible)] xl:inline">{message}</span>}
    </div>
  );
}
