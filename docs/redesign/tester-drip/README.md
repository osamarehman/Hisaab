# Hisaab tester email drip

Three plain-text emails sent from hisaab@shipdeck.dev to the Play "MVP Testers"
list, a few at a time, to get 12+ testers into Hisaab's closed test for 14 days.

| Step | File | Sent |
|---|---|---|
| 1 | `emails/01-invite.txt` | first run that reaches the person |
| 2 | `emails/02-reminder.txt` | 3 days after step 1 |
| 3 | `emails/03-feedback.txt` | 7 days after step 2 (day 10) |

`drip.py` sends at most `--batch` emails per run (default 5), due follow-ups
first, only 10:00-20:00 Pakistan time, with 30-90 s between emails. It records
each send in a state file, so re-running never repeats an email.

The recipient list, state and suppress files hold personal data. Keep them
outside git, under `/root/hisaab-drip/` on the server.

## Server setup

1. Mailbox: create `hisaab@shipdeck.dev` on the shipdeck mail server. Store its
   password in `/root/hisaab-drip/smtp-password` (`chmod 600`).
2. Deliverability: confirm shipdeck.dev has SPF, DKIM signing and DMARC for the
   sending server. Send one test to a Gmail address and check "Show original"
   shows `SPF: PASS`, `DKIM: PASS`.
3. Recipients: export the "MVP Testers" email list from Play Console (Testing >
   Closed testing > Alpha > Testers) as CSV. Save it as
   `/root/hisaab-drip/recipients.csv` with an `email` header (and optional `name`).
4. Env file `/root/hisaab-drip/env` (`chmod 600`):

   ```
   SMTP_HOST=<mail server host>
   SMTP_PORT=587
   SMTP_USER=hisaab@shipdeck.dev
   SMTP_PASSWORD_FILE=/root/hisaab-drip/smtp-password
   DRIP_FROM=Usama from Hisaab <hisaab@shipdeck.dev>
   ```

5. Dry run, then one real email to yourself:

   ```
   cd /root/Hisaab/docs/redesign/tester-drip
   set -a; . /root/hisaab-drip/env; set +a
   python3 drip.py --recipients /root/hisaab-drip/recipients.csv \
     --state /root/hisaab-drip/state.json --suppress /root/hisaab-drip/suppress.txt --dry-run
   ```

   For the self-test, use a one-line CSV with your own address and a separate
   `--state /tmp/drip-test.json`.

6. Cron (every 2 hours, the script skips quiet hours itself):

   ```
   0 */2 * * * cd /root/Hisaab/docs/redesign/tester-drip && set -a && . /root/hisaab-drip/env && set +a && python3 drip.py --recipients /root/hisaab-drip/recipients.csv --state /root/hisaab-drip/state.json --suppress /root/hisaab-drip/suppress.txt >> /root/hisaab-drip/drip.log 2>&1
   ```

## Running it

- Progress: add `--status` to the command above.
- Someone replies "stop", or an email bounces: add the address to
  `/root/hisaab-drip/suppress.txt`. It is never emailed again.
- Pause: comment out the cron line. Resume by restoring it; nothing is resent.
