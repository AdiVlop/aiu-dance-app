// Deno Edge Function - Upsert contact în Brevo la confirmare email
// Env necesare: BREVO_API_KEY, BREVO_LIST_ID (numeric, opțional), HOOK_SECRET (validare Webhook)

interface Payload {
  email: string;
  firstName?: string | null;
  lastName?: string | null;
}

const BREVO_API_KEY = Deno.env.get("BREVO_API_KEY")!;
const LIST_ID = Number(Deno.env.get("BREVO_LIST_ID") || 0);
const HOOK_SECRET = Deno.env.get("HOOK_SECRET") || "";

export default async (req: Request) => {
  console.log("🎭 AIU Dance - Brevo upsert contact function called");
  
  // Permitem doar POST și verificăm secretul
  if (req.method !== "POST") {
    console.log("❌ Method not allowed:", req.method);
    return new Response("Method Not Allowed", { status: 405 });
  }
  
  const incomingSecret = req.headers.get("x-hook-secret") || "";
  if (HOOK_SECRET && incomingSecret !== HOOK_SECRET) {
    console.log("❌ Invalid hook secret. Expected:", HOOK_SECRET, "Got:", incomingSecret);
    return new Response("Forbidden", { status: 403 });
  }

  try {
    const { email, firstName, lastName } = (await req.json()) as Payload;
    console.log("📧 Processing contact:", { email, firstName, lastName });
    
    if (!email) {
      console.log("❌ Email is required");
      return new Response(JSON.stringify({ error: "email is required" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Pregătește payload-ul pentru Brevo
    const brevoPayload = {
      email,
      updateEnabled: true, // upsert - actualizează dacă există, creează dacă nu
      ...(LIST_ID ? { listIds: [LIST_ID] } : {}),
      attributes: {
        FIRSTNAME: firstName ?? null,
        LASTNAME: lastName ?? null,
        SOURCE: "AIU Dance",
        SIGNUP_DATE: new Date().toISOString(),
      },
    };

    console.log("🚀 Sending to Brevo API:", JSON.stringify(brevoPayload, null, 2));

    const res = await fetch("https://api.brevo.com/v3/contacts", {
      method: "POST",
      headers: {
        "api-key": BREVO_API_KEY,
        "accept": "application/json",
        "content-type": "application/json",
      },
      body: JSON.stringify(brevoPayload),
    });

    const data = await res.json().catch(() => ({}));
    
    if (res.ok) {
      console.log("✅ Contact upserted successfully in Brevo:", data);
    } else {
      console.log("❌ Brevo API error:", res.status, data);
    }

    return new Response(JSON.stringify({ 
      ok: res.ok, 
      status: res.status, 
      data,
      message: res.ok ? "Contact upserted successfully" : "Failed to upsert contact"
    }), {
      status: res.ok ? 200 : res.status,
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    console.log("❌ Function error:", e);
    return new Response(JSON.stringify({ 
      error: String(e),
      message: "Internal server error"
    }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
};
