import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function POST() {
  const supabase = await createClient();
  const { data: claimsData, error: claimsError } = await supabase.auth.getClaims();
  const userId = claimsData?.claims?.sub;

  if (claimsError || !userId) {
    return NextResponse.json({ message: "Session invalide." }, { status: 401 });
  }

  const { error } = await supabase
    .from("parametres_firme")
    .update({ kill_switch_active: true, agents_geles: true })
    .eq("proprietaire_id", userId);

  if (error) {
    return NextResponse.json({ message: "Impossible de geler la firme." }, { status: 500 });
  }

  return NextResponse.json({ message: "Agents arrêtés, ordres en attente annulés et portefeuille gelé." });
}
