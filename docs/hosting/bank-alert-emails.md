# Bank alert emails

Households forward their bank's alert emails to a private address such as
`alerts+k7f3q9x2m4abc1d0e9fg@in.hisaab.shipdeck.dev`. Each email becomes a **pending**
transaction (or an alert waiting for an account), which the user approves or
rejects in the app. Nothing is posted without review: forwarded mail can't be
authenticated against the bank, so the secret address plus the household's
allowed-senders list is the only gate.

Mail reaches Rails through the host's docker-mailserver (`mail.runova.dev`,
config in `/opt/docker-mailserver`), which pipes every message for the
subdomain to a small script that posts it to Action Mailbox's relay ingress.
Postfix keeps and retries a message the app can't take, for days.

```
bank → user's Gmail/Outlook rule → alerts+<token>@in.hisaab.shipdeck.dev
     → MX mail.runova.dev (docker-mailserver, Postfix transport "hisaab")
     → hisaab-ingress.sh → POST https://hisaab.shipdeck.dev/rails/action_mailbox/relay/inbound_emails
     → BankAlertsMailbox → BankAlert::Receiver
```

## 1. App settings

In the server's `.env`:

```
RAILS_INBOUND_EMAIL_PASSWORD=<long random string, e.g. openssl rand -hex 32>
BANK_ALERTS_EMAIL_DOMAIN=in.hisaab.shipdeck.dev
```

Restart the app. With the password blank the ingress refuses every message.

## 2. Mail server

In `/opt/docker-mailserver/docker-data/dms/config/` (mounted in the container
at `/tmp/docker-mailserver/`):

- `hisaab-ingress.sh` (root, 0755): reads the message on stdin and posts it
  with `curl`. Exit 75 keeps the message queued for retry; 69 bounces it.
- `hisaab-ingress.auth` (uid 5000, 0400): one line,
  `Authorization: Basic <base64 of actionmailbox:PASSWORD>`, so the password
  never appears in the process list. Rebuild it after changing the password:

  ```sh
  printf 'Authorization: Basic %s\n' "$(printf 'actionmailbox:%s' "$PASSWORD" | base64 -w0)" > hisaab-ingress.auth
  chown 5000:5000 hisaab-ingress.auth && chmod 0400 hisaab-ingress.auth
  ```
- `user-patches.sh` re-applies the Postfix settings on every container start:
  `relay_domains = in.hisaab.shipdeck.dev`, `transport_maps = inline:{
  in.hisaab.shipdeck.dev=hisaab: }`, `hisaab_destination_recipient_limit = 1`
  and the `hisaab` pipe service (`flags=O`, which adds `X-Original-To`, run as
  user `docker`). One recipient per delivery keeps `X-Original-To` on the
  household's own address: a forwarded alert's `To` header names the user's
  mailbox, not ours.

To apply without restarting the mail server, run the same `postconf` lines
with `docker exec mailserver …`, then `postfix check && postfix reload`.

## 3. DNS

One record in the `shipdeck.dev` zone; the apex's own MX is untouched:

```
in.hisaab.shipdeck.dev.  MX  10  mail.runova.dev.
```

Postfix rejects mail for a recipient domain with no MX or A record
(`reject_unknown_recipient_domain`), so nothing arrives before this exists.

An alert is marked `sender_verified` when the mail server's own
OpenDMARC verdict (its topmost `Authentication-Results` header, authserv-id
`BANK_ALERTS_AUTHSERV_ID`, default `mail.runova.dev`) is `dmarc=pass` for the
sender's domain. The app shows unverified alerts with a warning; approval is
still required either way.

## 4. Check it

Without DNS, through the queue:

```sh
printf 'Subject: check\n\nhi\n' | docker exec -i mailserver sendmail alerts+test@in.hisaab.shipdeck.dev
docker exec mailserver grep 'relay=hisaab' /var/log/mail/mail.log | tail -1   # status=sent
```

With DNS in place, send a mail to `alerts+test@in.hisaab.shipdeck.dev` from
any outside account. The app's debug log then shows a `bank_alert_email` entry
"No household inbox for recipients". A household's real address (from
`GET /api/v1/email_inbox` or the app's settings) receives alerts from the
senders it allows.

## Adding a bank

Parsers live in `app/models/bank_alert/parsers/`, one class per bank, chosen
by sender domain in `BankAlert::Parser::PARSERS`. Each returns amount,
currency, direction (`in`/`out`), the account's last four digits, when it
happened and the payee. Alerts from an allowed sender that no parser reads are
kept as `unparsed`.
