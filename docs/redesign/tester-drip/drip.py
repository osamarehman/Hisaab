#!/usr/bin/env python3
"""Send the Hisaab tester emails a few at a time over SMTP.

Run from cron every couple of hours. Each run sends at most --batch emails,
follow-ups that are due before new invites, and only between 10:00 and 20:00
Pakistan time. Progress lives in a JSON state file, so a run can stop at any
point and the next one picks up where it left off.

Files (all outside git, they hold personal data):
  --recipients  CSV with an "email" column and an optional "name" column
  --state       JSON written by this script
  --suppress    one email per line; never sent to (replied "stop", bounced)

SMTP settings come from the environment:
  SMTP_HOST, SMTP_PORT (default 587, STARTTLS; 465 uses SSL), SMTP_USER,
  SMTP_PASSWORD_FILE (path to a root-only file holding the password),
  DRIP_FROM (default "Usama from Hisaab <hisaab@shipdeck.dev>").
"""

import argparse
import csv
import json
import os
import random
import smtplib
import sys
import time
from datetime import datetime, timedelta, timezone
from email.message import EmailMessage
from email.utils import formatdate, make_msgid, parseaddr
from pathlib import Path
from zoneinfo import ZoneInfo

HERE = Path(__file__).resolve().parent
# (template, days to wait after the previous email in the sequence)
STEPS = [("01-invite.txt", 0), ("02-reminder.txt", 3), ("03-feedback.txt", 7)]
LOCAL_TZ = ZoneInfo("Asia/Karachi")
SEND_HOURS = range(10, 20)


def load_template(name):
    subject_line, body = (HERE / "emails" / name).read_text(encoding="utf-8").split("\n\n", 1)
    assert subject_line.startswith("Subject: "), f"{name} must start with 'Subject: '"
    return subject_line[len("Subject: "):].strip(), body


def load_recipients(path):
    with open(path, newline="", encoding="utf-8-sig") as f:
        rows = csv.DictReader(f)
        seen = {}
        for row in rows:
            email = (row.get("email") or "").strip().lower()
            if "@" in email and email not in seen:
                seen[email] = (row.get("name") or "").strip()
    return seen


def load_lines(path):
    if not path or not Path(path).exists():
        return set()
    return {line.strip().lower() for line in Path(path).read_text(encoding="utf-8").splitlines() if line.strip()}


def due_jobs(recipients, state, suppressed, now):
    """Follow-ups that are due first (oldest first), then new invites."""
    follow_ups, invites = [], []
    for email in recipients:
        if email in suppressed:
            continue
        entry = state.get(email)
        if entry is None:
            invites.append((email, 0))
            continue
        step = entry["step"] + 1
        if step >= len(STEPS):
            continue
        last = datetime.fromisoformat(entry["sent_at"])
        if now - last >= timedelta(days=STEPS[step][1]):
            follow_ups.append((last, email, step))
    follow_ups.sort()
    return [(email, step) for _, email, step in follow_ups] + invites


def build_message(sender, email, name, step):
    subject, body = load_template(STEPS[step][0])
    first_name = name.split()[0] if name else "there"
    msg = EmailMessage()
    msg["From"] = sender
    msg["To"] = email
    msg["Reply-To"] = parseaddr(sender)[1]
    msg["Subject"] = subject
    msg["Date"] = formatdate(localtime=True)
    msg["Message-ID"] = make_msgid(domain=parseaddr(sender)[1].split("@")[1])
    msg["List-Unsubscribe"] = f"<mailto:{parseaddr(sender)[1]}?subject=stop>"
    msg.set_content(body.replace("{name}", first_name))
    return msg


def smtp_connection():
    host = os.environ["SMTP_HOST"]
    port = int(os.environ.get("SMTP_PORT", "587"))
    password = Path(os.environ["SMTP_PASSWORD_FILE"]).read_text(encoding="utf-8").strip()
    server = smtplib.SMTP_SSL(host, port, timeout=30) if port == 465 else smtplib.SMTP(host, port, timeout=30)
    if port != 465:
        server.starttls()
    server.login(os.environ["SMTP_USER"], password)
    return server


def save_state(path, state):
    tmp = Path(str(path) + ".tmp")
    tmp.write_text(json.dumps(state, indent=2, sort_keys=True), encoding="utf-8")
    tmp.replace(path)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--recipients", required=True)
    parser.add_argument("--state", required=True)
    parser.add_argument("--suppress")
    parser.add_argument("--batch", type=int, default=5)
    parser.add_argument("--dry-run", action="store_true", help="print what would be sent, send nothing")
    parser.add_argument("--ignore-hours", action="store_true", help="send outside 10:00-20:00 PKT")
    parser.add_argument("--status", action="store_true", help="print progress and exit")
    args = parser.parse_args()

    recipients = load_recipients(args.recipients)
    state_path = Path(args.state)
    state = json.loads(state_path.read_text(encoding="utf-8")) if state_path.exists() else {}
    suppressed = load_lines(args.suppress)
    now = datetime.now(timezone.utc)

    if args.status:
        counts = [sum(1 for e in state.values() if e["step"] == i) for i in range(len(STEPS))]
        print(f"recipients {len(recipients)}, suppressed {len(suppressed & recipients.keys())}, "
              f"not started {len([e for e in recipients if e not in state])}")
        for (name, _), count in zip(STEPS, counts):
            print(f"  last sent {name}: {count}")
        print(f"due now: {len(due_jobs(recipients, state, suppressed, now))}")
        return

    if not args.ignore_hours and now.astimezone(LOCAL_TZ).hour not in SEND_HOURS:
        print("outside send hours, nothing sent")
        return

    jobs = due_jobs(recipients, state, suppressed, now)[: args.batch]
    if not jobs:
        print("nothing due")
        return

    sender = os.environ.get("DRIP_FROM", "Usama from Hisaab <hisaab@shipdeck.dev>")
    server = None if args.dry_run else smtp_connection()
    try:
        for i, (email, step) in enumerate(jobs):
            msg = build_message(sender, email, recipients[email], step)
            if args.dry_run:
                print(f"[dry run] {STEPS[step][0]} -> {email} | {msg['Subject']}")
                continue
            try:
                server.send_message(msg)
            except smtplib.SMTPRecipientsRefused as error:
                print(f"refused {email}: {error}", file=sys.stderr)
                continue
            state[email] = {"step": step, "sent_at": datetime.now(timezone.utc).isoformat()}
            save_state(state_path, state)
            print(f"sent {STEPS[step][0]} -> {email}")
            if i < len(jobs) - 1:
                time.sleep(random.uniform(30, 90))
    finally:
        if server:
            server.quit()


if __name__ == "__main__":
    main()
