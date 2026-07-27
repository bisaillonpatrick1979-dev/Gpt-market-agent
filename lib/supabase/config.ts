const fallbackSupabaseUrl = "https://zdnbjpszgcftykteuyjl.supabase.co";
const fallbackPublishableKey = "sb_publishable_lwdx2_uHzJs0m61IL4oWPQ_ofqMR_vF";

export const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL ?? fallbackSupabaseUrl;
export const supabasePublishableKey =
  process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY ?? fallbackPublishableKey;
