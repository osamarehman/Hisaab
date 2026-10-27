# Household edition: API contract

The household edition of the mobile app (PKR, manual entry, statement import,
labels) relies on these API v1 additions. "Label" in the app is a Sure
**category**; "auto-label keyword" is a Sure **rule** with one
`transaction_name` contains-condition and one `set_transaction_category`
action. All endpoints use the existing API auth (Bearer token or `X-Api-Key`)
and family scoping.

## Transactions

- `GET /api/v1/transactions?uncategorized=true` returns only transactions
  without a category, excluding transfers. Combines with `start_date`,
  `end_date`, `account_id`, `search`, pagination.
- Every transaction JSON gains:
  ```json
  "attachments": [
    { "id": "<signed blob id>", "filename": "bill.jpg", "content_type": "image/jpeg",
      "byte_size": 412000, "url": "https://…/rails/active_storage/blobs/redirect/…" }
  ]
  ```
- `POST /api/v1/transactions/:transaction_id/attachments` (multipart,
  `attachments[]` one or more files; jpeg/png/webp/gif/pdf, 10 MB each, 10 per
  transaction). Returns `201` with the full transaction JSON.
- `DELETE /api/v1/transactions/:transaction_id/attachments/:id` returns `204`.

## Categories (labels)

- Existing: `GET /api/v1/categories`, `POST /api/v1/categories`
  (`category[name, color, icon, parent_id]`).
- New: `PATCH /api/v1/categories/:id` (same params) → category JSON;
  `DELETE /api/v1/categories/:id` → `204` (transactions become uncategorized).

## Rules (auto-label keywords)

- Existing: `GET /api/v1/rules`.
- New: `POST /api/v1/rules` with
  `{ "rule": { "keyword": "K-ELECTRIC", "category_id": "<uuid>", "apply_to_existing": true } }`
  creates an active transaction rule (name contains keyword → set category).
  With `apply_to_existing` it also applies to existing matching transactions.
  Returns `201` with rule JSON.
- New: `DELETE /api/v1/rules/:id` → `204`.

## Statement imports

- `POST /api/v1/imports` (multipart) with `type=PdfImport`, `account_id`,
  `file` (PDF). Creates a statement import and starts AI extraction in the
  background (needs an OpenAI or Anthropic key configured on the server).
  Returns `202` with import JSON. CSV continues to work with
  `type=TransactionImport` as before.
- `GET /api/v1/imports/:id` → includes `status` (`pending`, `importing`,
  `complete`, `failed`), `rows_count`, `error`, and for PDF imports the
  statement date range when known.
- New: `POST /api/v1/imports/:id/publish` publishes a pending import (creates
  the transactions; rules then run automatically) → `202` with import JSON.

## Family defaults

- New families default to `currency: "PKR"`, `country: "PK"`.
- `DISABLE_BANK_SYNC=true` hides bank-provider connection UI and adapters.
