import { createServerClient } from "@supabase/ssr";
import { NextResponse } from "next/server";

function safeNext(value: string | null) {
  return value?.startsWith("/") && !value.startsWith("//") ? value : "/onboard";
}

export async function GET(request: Request) {
  const url = new URL(request.url);
  const code = url.searchParams.get("code");
  const response = NextResponse.redirect(new URL(safeNext(url.searchParams.get("next")), url.origin));

  if (!code) {
    return NextResponse.redirect(new URL("/onboard", url.origin));
  }

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL ?? "https://placeholder.supabase.co",
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ?? "placeholder-anon-key",
    {
      db: { schema: "local_edge" },
      cookies: {
        getAll() {
          return request.headers
            .get("cookie")
            ?.split(";")
            .map((part) => {
              const [name, ...value] = part.trim().split("=");
              return { name, value: value.join("=") };
            }) ?? [];
        },
        setAll(cookies) {
          cookies.forEach(({ name, value, options }) => response.cookies.set(name, value, options));
        },
      },
    },
  );

  const { error } = await supabase.auth.exchangeCodeForSession(code);
  if (error) {
    return NextResponse.redirect(new URL("/onboard", url.origin));
  }

  return response;
}
