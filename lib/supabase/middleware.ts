import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";

export async function updateSession(request: NextRequest) {
  let response = NextResponse.next({ request });
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const publishableKey = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;

  if (!url || !publishableKey) {
    return response;
  }

  const supabase = createServerClient(url, publishableKey, {
    cookies: {
      getAll: () => request.cookies.getAll(),
      setAll(cookiesToSet) {
        cookiesToSet.forEach(({ name, value }) => request.cookies.set(name, value));
        response = NextResponse.next({ request });
        cookiesToSet.forEach(({ name, value, options }) => {
          response.cookies.set(name, value, options);
        });
      }
    }
  });

  const { data } = await supabase.auth.getClaims();
  const isAuthenticated = Boolean(data?.claims?.sub);
  const isAuthRoute = request.nextUrl.pathname.startsWith("/connexion") || request.nextUrl.pathname.startsWith("/auth");
  const isPublicRoute = isAuthRoute || request.nextUrl.pathname.startsWith("/_next") || request.nextUrl.pathname === "/favicon.ico";

  if (!isAuthenticated && !isPublicRoute) {
    const redirectUrl = request.nextUrl.clone();
    redirectUrl.pathname = "/connexion";
    return NextResponse.redirect(redirectUrl);
  }

  if (isAuthenticated && request.nextUrl.pathname === "/connexion") {
    const redirectUrl = request.nextUrl.clone();
    redirectUrl.pathname = "/salle";
    return NextResponse.redirect(redirectUrl);
  }

  return response;
}
