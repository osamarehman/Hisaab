# Hisaab

Hisaab is a household finance app. A family shares one set of accounts, logs spending, plans budgets, tracks bills and loans, and sees where the month's money went. It works in any currency.

Hisaab runs as a Rails server with a web app, Android and iOS apps (Flutter), and a macOS desktop shell. Everything talks to the same server, so the whole household sees the same numbers.

## What it does

- **Shared household books.** Invite family members, choose which accounts each person sees, and keep one ledger for the house.
- **Bank alert emails.** Forward your bank's transaction alerts to a private address and each one becomes a pending transaction you approve or reject. See [bank alert emails](docs/hosting/bank-alert-emails.md).
- **Budgets, bills and goals.** Monthly budgets by category, recurring bills with reminders, and savings goals.
- **Interest-free by default.** Loans and savings are tracked without interest (no riba). Set `INTEREST_FREE=false` to turn interest back on.
- **Reports.** Cash flow, net worth, spending against your usual months, and a monthly PDF report.
- **AI assistant.** Ask questions about your money in plain language. Works with OpenAI or any OpenAI-compatible endpoint such as OpenRouter. See [AI setup](docs/hosting/ai.md).
- **English and Urdu**, plus the other languages in `config/locales`, with right-to-left layout support.
- **API and MCP.** A documented HTTP API ([OpenAPI spec](docs/api/openapi.yaml)) and an [MCP endpoint](docs/hosting/mcp.md) for AI clients.

## Clients

| Client | Where | Notes |
| --- | --- | --- |
| Web | Any modern browser | The full app, including settings and administration. |
| Android and iOS | [`mobile/`](mobile/README.md) | Flutter app for daily use: balances, transactions, budgets, bank alerts. |
| macOS | [`desktop/`](desktop/README.md) | Tauri shell around the web app. |
| API clients and AI agents | [`docs/api`](docs/api), [MCP guide](docs/hosting/mcp.md) | Same accounts and permissions as the apps. |

More detail in [docs/clients.md](docs/clients.md).

## Self-hosting

Hisaab ships as a Docker Compose stack: Rails web, a Sidekiq worker, PostgreSQL and Redis.

```sh
cp .env.household.example .env   # fill in APP_DOMAIN, POSTGRES_PASSWORD, SECRET_KEY_BASE
docker compose -f compose.household.yml up -d
```

Put a reverse proxy with TLS in front of it. The full walkthrough is in the [Docker hosting guide](docs/hosting/docker.md).

## Local development

Requirements:

- Ruby (version in `.ruby-version`)
- PostgreSQL (latest stable)
- Redis 5.4 or newer

```sh
cd Hisaab
cp .env.local.example .env.local
bin/setup
bin/dev

# Optional: load demo data
rake demo_data:default
```

Open http://localhost:3000. With demo data loaded, sign in as `user@example.com` / `Password1!`.

Before opening a pull request, run the checks in the [development guide](docs/llm-guides/development.md#before-opening-a-pull-request): `bin/rails test`, system tests where relevant, Rubocop, ERB lint, Biome and Brakeman. Contribution rules are in [CONTRIBUTING.md](CONTRIBUTING.md).

## Currency

Each household picks its own currency in Settings. Pakistani rupee (PKR) is the default for new households; every ISO 4217 currency is supported, and accounts can hold other currencies alongside the household one.

## Security

Report vulnerabilities as described in [SECURITY.md](SECURITY.md). Please don't open public issues for them.

## License

Hisaab is released under the [GNU Affero General Public License v3.0](LICENSE). If you run a modified version for other people over a network, you must offer them its source code.
