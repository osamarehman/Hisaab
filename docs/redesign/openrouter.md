# Household edition: AI through OpenRouter

The assistant (chat), PDF statement reading and auto-labelling all use the
server's OpenAI-compatible LLM provider. OpenRouter speaks the same API, so one
OpenRouter key powers all three. Nothing in the code is OpenRouter-specific.

## Server environment

```bash
OPENAI_ACCESS_TOKEN=sk-or-v1-...                  # your OpenRouter key
OPENAI_URI_BASE=https://openrouter.ai/api/v1
OPENAI_MODEL=google/gemma-4-31b-it:free           # any model; see below
# Optional: lets OpenRouter attribute requests to the app
OPENAI_EXTRA_HEADERS={"HTTP-Referer":"https://<your-domain>","X-Title":"Sure"}
```

These can also be set in Settings → Self-hosting (AI provider) instead of the
environment. With a custom `OPENAI_URI_BASE` Sure uses the chat-completions
API and reads PDFs as extracted text, which works with OpenRouter.

## Choosing a free model

The assistant answers questions by calling tools (look up transactions,
budgets, balance sheet), so the model **must support tool calling**. List the
free ones that do:

```bash
curl -s https://openrouter.ai/api/v1/models | python -c "import json,sys
for m in json.load(sys.stdin)['data']:
  if m['id'].endswith(':free') and 'tools' in (m.get('supported_parameters') or []): print(m['id'])"
```

On 2026-10-27 that included `google/gemma-4-31b-it:free`,
`nvidia/nemotron-3-ultra-550b-a55b:free` and `nvidia/nemotron-3.5-super-vl:free`.
Free models change often and have tight rate limits (OpenRouter raises the
daily free-request cap once the account has bought credits). If answers stop
or tool calls fail, switch `OPENAI_MODEL` to another model from the list.

## Privacy

Questions and the transaction data the assistant looks up are sent to
OpenRouter and the model's host. Free endpoints may log prompts for training;
check the model's page on openrouter.ai and pick one whose data policy you
accept, or use a paid model with a no-logging policy.
