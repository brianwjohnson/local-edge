import { createClient } from "@supabase/supabase-js";

/** Add NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_ANON_KEY to .env.local. */
export const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL ?? "https://placeholder.supabase.co",
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ?? "placeholder-anon-key",
);
