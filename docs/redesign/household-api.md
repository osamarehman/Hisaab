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
  `duplicate_upload`; `403` when the user may not import statements. CSV
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

## Family defaults

- New families default to `currency: "PKR"`, `country: "PK"`.
- `DISABLE_BANK_SYNC=true` hides bank-provider connection UI and adapters.
