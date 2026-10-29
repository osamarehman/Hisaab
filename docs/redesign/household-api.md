# Household edition: API contract

The household edition of the mobile app (PKR, manual entry, statement import,
labels) relies on these API v1 additions. "Label" in the app is a Sure
**category**; "auto-label keyword" is a Sure **rule** with one
`transaction_name` contains-condition and one `set_transaction_category`
action. All endpoints use the existing API auth (Bearer token or `X-Api-Key`)
and family scoping.

## Transactions

- `GET /api/v1/transactions?uncategorized=true` returns only transactions
  without a category, excluding transfers and excluded rows. Combines with
  `start_date`, `end_date`, `account_id`, `search`, pagination.
- "Not an expense" (ATM withdrawal, moving money between own accounts):
  `PATCH /api/v1/transactions/:id` with `{ "transaction": { "excluded": true } }`.
  This is the web app's Exclude toggle (`entries.excluded`): the row stays on
  the account, leaves budgets/reports and the `uncategorized=true` queue, and
  the JSON shows `"excluded": true`. Send `false` to undo; omit to leave it.
  Split parents cannot be un-excluded (`422`).
- Every transaction JSON gains:
  ```json
  "attachments": [
    { "id": "<attachment uuid>", "filename": "bill.jpg", "content_type": "image/jpeg",
      "byte_size": 412000, "url": "https://…/api/v1/transactions/<transaction id>/attachments/<attachment uuid>" }
  ]
  ```
  `id` is what `DELETE …/attachments/:id` takes. `url` is an API endpoint, not
  an Active Storage blob URL (those need a browser session): fetch it with the
  same `Authorization` / `X-Api-Key` header as every other call
  (e.g. `Image.network(url, headers: …)`). It streams the file inline.
- `GET /api/v1/transactions/:transaction_id/attachments/:id` → the file bytes.
- `POST /api/v1/transactions/:transaction_id/attachments` (multipart,
  `attachments[]` one or more files; jpeg/png/webp/gif/pdf, 10 MB each, 10 per
  transaction). Returns `201` with the full transaction JSON.
- `DELETE /api/v1/transactions/:transaction_id/attachments/:id` returns `204`.
- Upload errors: `422` `{ "error": "validation_failed", "message": "…" }` for no
  files, wrong type, too large or over the 10-file limit; `403` when the user
  cannot write to the account.

## Categories (labels)

- Existing: `GET /api/v1/categories`, `POST /api/v1/categories`
  (`category[name, color, icon, parent_id]`).
- New: `PATCH /api/v1/categories/:id` (same params) → category JSON;
  `DELETE /api/v1/categories/:id` → `204` (transactions become uncategorized,
  subcategories become top-level). Errors use
  `{ "error": "unprocessable_entity", "message": "…" }` (`422`).

## Rules (auto-label keywords)

- Existing: `GET /api/v1/rules`.
- New: `POST /api/v1/rules` with
  `{ "rule": { "keyword": "K-ELECTRIC", "category_id": "<uuid>", "apply_to_existing": true } }`
  creates an active transaction rule (name contains keyword → set category).
  With `apply_to_existing` it also applies to existing matching transactions.
  Returns `201` with rule JSON (`{ "data": { … } }`, like `GET /rules/:id`).
  Rows whose category the user set by hand are not overwritten. `422`
  `validation_failed` for a blank keyword or a category outside the family.
- New: `DELETE /api/v1/rules/:id` → `204`.

## Statement imports

- `POST /api/v1/imports` (multipart) with `type=PdfImport`, `account_id`,
  `file` (PDF). Creates a statement import and starts AI extraction in the
  background (needs an OpenAI or Anthropic key configured on the server).
  Returns `202` with import JSON. A PDF `file` is also detected without
  `type`. `account_id` must be an account the user can write to (else `422`).
  Errors: `422` `invalid_file_type` (not a PDF), `file_too_large` (25 MB),
  `duplicate_upload`, `ai_unavailable` (the household is outside
  `AI_ALLOWED_EMAILS`; `message` tells the user to import CSV instead);
  `403` when the user may not import statements. CSV
  continues to work with `type=TransactionImport` as before (`201`).
- `GET /api/v1/imports/:id` → `data` includes `status` (`pending`,
  `importing`, `complete`, `failed`), `rows_count`, `error` (null when none),
  and for PDF imports
  `"statement": { "period_start_on": "2026-09-01" | null, "period_end_on": … }`.
  A PDF import is `importing` while AI extraction runs, then `pending` with
  rows to review (or `complete` when the document had no transactions).
- New: `POST /api/v1/imports/:id/publish` publishes a pending import (creates
  the transactions; rules then run automatically) → `202` with import JSON.
  `422` `not_publishable` (no account, extraction not finished, or invalid
  rows) or `max_row_count_exceeded`; `403` without write access to the
  import's accounts.

## Reports (PDF export)

- New: `GET /api/v1/reports/export.pdf?start_date=2026-09-01&end_date=2026-09-30`
  returns `application/pdf` (attachment, `hisaab-report-<start>-to-<end>.pdf`,
  `Cache-Control: private, no-store`). Read scope is enough.
  - Page one: "Hisaab report", household name, period, labels and accounts
    included, money in / out / net, and a table by label (in, out, count).
    Then every entry grouped by month (date, description, label, account,
    in or out) with a subtotal per month.
  - `category_ids[]` (optional): only these labels and their sublabels. Omit
    for every label.
  - `include_uncategorized` (optional): include unlabelled rows. Defaults to
    `true` without `category_ids`, `false` with them; send
    `include_uncategorized=true` alone for unlabelled rows only.
  - `account_ids[]` (optional): only these accounts; omit for every account
    the user can see.
  - Left out, as in the month view: transfers between own accounts
    (`funds_movement`, `cc_payment`), excluded rows (including split
    parents) and pending provider rows. Loan payments and investment
    contributions count as money out.
  - Amounts stay in each account's currency ("Rs 2,500" for PKR, decimals
    only when not whole); totals are per currency.
  - `422` `invalid_period` (missing/invalid dates, start after end, more
    than 24 months, or more than 5,000 entries), `invalid_category` /
    `invalid_account` (an id outside the household or not visible to the
    user).
- The web Reports page has a matching **PDF** button
  (`GET /reports/household_pdf?start_date=&end_date=`, every label and
  account).

## Family defaults

- New families default to `currency: "PKR"`, `country: "PK"`.
- `DISABLE_BANK_SYNC=true` hides bank-provider connection UI and adapters.

## Accounts

The app lets the household create the accounts money is paid from and to.
These use the web's creation and balance paths, so opening balances and
balance changes are recorded as valuations exactly as on the web.

- New: `POST /api/v1/accounts` with
  `{ "account": { "name": "Cash in hand", "accountable_type": "Depository", "subtype": "cash", "balance": "5000" } }`
  creates a manual account owned by the caller and returns `201` with the
  account JSON (same as `GET /accounts/:id`).
  - `accountable_type`: `Depository`, `CreditCard`, `Loan`, `OtherAsset` or
    `OtherLiability`; anything else is `422`.
  - `subtype` (optional) must be one of the type's subtypes, e.g. Depository
    `cash`, `checking`, `savings`; Loan `other`; CreditCard `credit_card`.
  - `balance` (optional, default `0`): decimal string. For liabilities it is
    the positive amount owed.
  - `currency` (optional): defaults to the family currency (PKR).
  - `opening_balance_date` (optional, `YYYY-MM-DD`, not in the future):
    defaults to two years ago, as on the web.
  - `422` `validation_failed` for a blank name, unknown subtype/currency or a
    non-numeric balance; `403` for a read-only key or a guest.
- New: `PATCH /api/v1/accounts/:id` with `{ "account": { "name": "…", "balance": "…" } }`.
  Both optional. A changed `balance` sets today's balance (a valuation), like
  the web's balance update. `403` without owner/full-control permission on
  the account, `404` outside the family, `422` for a blank name or
  non-numeric balance.
- New: `DELETE /api/v1/accounts/:id` → `204`. Like the web, the account is
  marked `pending_deletion` and removed by a background job; linked
  (bank-synced) accounts return `422`. Same `403`/`404` rules as update.

## AI access

`AI_ALLOWED_EMAILS` (comma-separated, case-insensitive) limits the server's
LLM quota on an open-signup instance. Only households with one of those
emails as an active member get the assistant (`ai_enabled` stays false in
`/api/v1/auth/*` user payloads and `PATCH /auth/enable_ai` is refused), AI
auto-labelling and PDF statement reading. Empty means every household may
use AI. `Family#ai_allowed?` and `Family#llm_provider` are the single check.

## Account deletion

- `DELETE /api/v1/users/me` (write scope) deactivates the caller, revokes
  every token and queues `UserPurgeJob`, which deletes the household when the
  caller is its last member and otherwise hands their accounts to another
  member. `422` with `details` when an admin still has other members.
- `/account-deletion` is the public page explaining in-app, web and email
  deletion (the URL Google Play asks for). `/privacy` and `/terms` are the
  public legal pages.
