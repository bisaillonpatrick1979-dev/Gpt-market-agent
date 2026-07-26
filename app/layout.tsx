import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "GPT Market Agent",
  description: "Salle des marchés multi-agents en environnement simulé."
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="fr">
      <body>{children}</body>
    </html>
  );
}
