import { createBrowserClient } from "@supabase/ssr";

/**
 * Browser client for Local Edge only. The SSR client persists its PKCE session
 * in cookies, so the callback route and subsequent navigation share a session.
 */
export const supabase = createBrowserClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL ?? "https://placeholder.supabase.co",
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ?? "placeholder-anon-key",
  {
    db: { schema: "local_edge" },
    auth: { flowType: "pkce" },
  },
);
