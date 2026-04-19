import "@supabase/functions-js/edge-runtime.d.ts";
import Stripe from "https://esm.sh/stripe@14?target=deno";

Deno.serve(async (req) => {
  try {
    const stripeSecret = Deno.env.get("STRIPE_SECRET_KEY");

    if (!stripeSecret) {
      return new Response(
        JSON.stringify({ error: "Missing Stripe secret" }),
        { status: 500 }
      );
    }

    const stripe = new Stripe(stripeSecret, {
      apiVersion: "2023-10-16",
    });

    const { amount, currency } = await req.json();

    if (!amount) {
      return new Response(
        JSON.stringify({ error: "Missing amount" }),
        { status: 400 }
      );
    }

    const paymentIntent = await stripe.paymentIntents.create({
      amount,
      currency: currency ?? "usd",
      automatic_payment_methods: { enabled: true },
    });

    return new Response(
      JSON.stringify({
        clientSecret: paymentIntent.client_secret,
        intentId: paymentIntent.id,
      }),
      {
        headers: { "Content-Type": "application/json" },
      }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500 }
    );
  }
});