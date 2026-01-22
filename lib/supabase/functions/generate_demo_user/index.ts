// deno-lint-ignore-file no-explicit-any
// Supabase Edge Function: generate_demo_user
// Creates a demo user with a random email/password and returns the credentials.
// CORS enabled, OPTIONS supported. Intended for unauthenticated use; set verify_jwt = false in config.toml for this function.

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CORS_HEADERS = {
  "access-control-allow-origin": "*",
  "access-control-allow-headers": "authorization, x-client-info, apikey, content-type",
  "access-control-allow-methods": "POST, OPTIONS",
  "access-control-max-age": "86400",
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const admin = createClient(SUPABASE_URL, SERVICE_ROLE, {
  auth: { persistSession: false },
});

function randomString(len = 16): string {
  const alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
  let out = "";
  crypto.getRandomValues(new Uint8Array(len)).forEach((n) => (out += alphabet[n % alphabet.length]));
  return out;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: { ...CORS_HEADERS } });
  }

  try {
    if (req.method !== "POST") {
      return new Response(JSON.stringify({ error: "Method not allowed" }), { status: 405, headers: { "content-type": "application/json", ...CORS_HEADERS } });
    }

    const now = Date.now();
    const email = `demo_${now}_${randomString(4)}@example.com`;
    const password = `${randomString(6)}-${randomString(6)}`;

    const { data, error } = await admin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      app_metadata: { demo: true },
      user_metadata: { name: "Demo User" },
    });

    if (error || !data?.user) {
      return new Response(JSON.stringify({ error: error?.message ?? "Failed to create user" }), { status: 500, headers: { "content-type": "application/json", ...CORS_HEADERS } });
    }

    return new Response(JSON.stringify({ email, password, user_id: data.user.id }), {
      status: 200,
      headers: { "content-type": "application/json", ...CORS_HEADERS },
    });
  } catch (e: any) {
    return new Response(JSON.stringify({ error: e?.message ?? String(e) }), { status: 500, headers: { "content-type": "application/json", ...CORS_HEADERS } });
  }
});
