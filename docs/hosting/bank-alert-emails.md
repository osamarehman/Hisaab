# Bank alert emails

Households forward their bank's alert emails to a private address such as
`k7f3q9x2m4abc1d0e9fg@in.hisaab.shipdeck.dev`. Each email becomes a **pending**
transaction (or an alert waiting for an account), which the user approves or
rejects in the app. Nothing is posted without review: forwarded mail can't be
authenticated against the bank, so the secret address plus the household's
allowed-senders list is the only gate.

Mail reaches Rails through Cloudflare Email Routing and a small Email Worker,
which posts the raw message to Action Mailbox's relay ingress. No mail server
on the host is involved.

```
bank → user's Gmail/Outlook rule → <token>@in.hisaab.shipdeck.dev
     → Cloudflare Email Routing (catch-all) → Email Worker
     → POST https://hisaab.shipdeck.dev/rails/action_mailbox/relay/inbound_emails
     → BankAlertsMailbox → BankAlert::Receiver
```

## 1. App settings

In the server's `.env`:

```
RAILS_INBOUND_EMAIL_PASSWORD=<long random string, e.g. openssl rand -hex 32>
BANK_ALERTS_EMAIL_DOMAIN=in.hisaab.shipdeck.dev
```

Restart the app. With the password blank the ingress refuses every message.

## 2. Cloudflare Email Routing on the subdomain

In the Cloudflare dashboard for `shipdeck.dev`:

1. **Email → Email Routing → Settings → Subdomains**: add `in.hisaab`.
   Cloudflare adds the MX and SPF (TXT) records for `in.hisaab.shipdeck.dev`.
   Check they're present under **DNS** (three `MX` records pointing at
   `route1/2/3.mx.cloudflare.net`, and a `TXT` `v=spf1 include:_spf.mx.cloudflare.net ~all`).
2. Create the Worker below (**Workers & Pages → Create → Hello World**, then
   replace the code). Under the Worker's **Settings → Variables and secrets**,
   add the secrets `INGRESS_URL`
   (`https://hisaab.shipdeck.dev/rails/action_mailbox/relay/inbound_emails`) and
   `INGRESS_PASSWORD` (the same value as `RAILS_INBOUND_EMAIL_PASSWORD`).
3. **Email → Email Routing → Routing rules → Catch-all address** for
   `in.hisaab.shipdeck.dev`: action **Send to a Worker**, choose the Worker,
   and enable it.

## Worker

```js
// Forwards every message for the bank-alert subdomain to Rails.
// X-Original-To carries the envelope recipient: a forwarded alert keeps the
// bank's To header, which names the user's own mailbox, not the household's.
export default {
  async email(message, env) {
    const raw = await new Response(message.raw).arrayBuffer();
    const header = new TextEncoder().encode(`X-Original-To: ${message.to}\r\n`);
    const body = new Uint8Array(header.length + raw.byteLength);
    body.set(header, 0);
    body.set(new Uint8Array(raw), header.length);

    const response = await fetch(env.INGRESS_URL, {
      method: "POST",
      headers: {
        "Content-Type": "message/rfc822",
        Authorization: "Basic " + btoa(`actionmailbox:${env.INGRESS_PASSWORD}`),
      },
      body,
    });

    // A rejection makes the sending server retry or bounce instead of
    // silently losing the alert.
    if (!response.ok) message.setReject(`Ingress returned ${response.status}`);
  },
};
```

## 3. Check it

Send a mail to `anything@in.hisaab.shipdeck.dev` from any account. The Worker's
logs should show a `204` from the ingress, and the app's debug log a
`bank_alert_email` entry "No household inbox for recipients". A household's
real address (from `GET /api/v1/email_inbox` or the app's settings) then
receives alerts from the senders it allows.

## Adding a bank

Parsers live in `app/models/bank_alert/parsers/`, one class per bank, chosen
by sender domain in `BankAlert::Parser::PARSERS`. Each returns amount,
currency, direction (`in`/`out`), the account's last four digits, when it
happened and the payee. Alerts from an allowed sender that no parser reads are
kept as `unparsed`.
