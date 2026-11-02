# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'API V1 Cash Flow', type: :request do
  let(:family) do
    Family.create!(
      name: 'API Family',
      currency: 'USD',
      locale: 'en',
      date_format: '%m-%d-%Y'
    )
  end

  let(:user) do
    family.users.create!(
      email: 'api-user@example.com',
      password: 'password123',
      password_confirmation: 'password123'
    )
  end

  let(:api_key) do
    key = ApiKey.generate_secure_key
    ApiKey.create!(
      user: user,
      name: 'API Docs Key',
      key: key,
      scopes: %w[read_write],
      source: 'web'
    )
  end

  let(:'X-Api-Key') { api_key.plain_key }

  path '/api/v1/cash_flow' do
    get 'Show cash flow and optional Sankey graph' do
      tags 'Cash Flow'
      description 'Server-calculated income, spending, savings, opening and closing cash position, spending by category, and daily cumulative comparison in family currency, for a month, a named period or a date range. Uses the authenticated user’s finance accounts and Sure reporting rules. Browser sessions do not authenticate this public API.'
      parameter name: :month, in: :query, required: false, schema: { type: :string, format: :date }, description: 'Non-future first day YYYY-MM-01; defaults to the current month in the family time zone.'
      parameter name: :include, in: :query, required: false, schema: { type: :string, enum: [ 'sankey' ] }, description: 'Append server-calculated graph to the monthly summary; cannot combine with view.'
      parameter name: :view, in: :query, required: false, schema: { type: :string, enum: [ 'sankey' ] }, description: 'Graph-only envelope; omits daily comparison. Accepts month or an explicit date range; cannot combine with include.'
      parameter name: :group_by, in: :query, required: false, schema: { type: :string, enum: %w[category account], default: 'category' }, description: 'Requires view=sankey. category: flows through one Cash Flow node; account: income categories flow through each account to expense categories (basis net_by_account).'
      parameter name: :period, in: :query, required: false, schema: { type: :string, enum: %w[last_3_months last_6_months last_12_months all_time] }, description: 'Named range instead of month. Last N months are whole calendar months including the current one. all_time starts at the oldest entry, so it opens at zero, and has no comparison. Cannot combine with month or start_date/end_date.'
      parameter name: :start_date, in: :query, required: false, schema: { type: :string, format: :date }, description: 'Inclusive ISO date, no later than today. Requires end_date; cannot combine with month or period.'
      parameter name: :end_date, in: :query, required: false, schema: { type: :string, format: :date }, description: 'Inclusive ISO date at or after start_date. A future end is capped at today for the summary; view=sankey keeps the explicit bounds.'
      security [ { apiKeyAuth: [] } ]
      produces 'application/json'

      response '200', 'summary returned' do
        schema anyOf: [ { '$ref' => '#/components/schemas/CashFlow' }, { '$ref' => '#/components/schemas/CashFlowGraph' } ]

        run_test!
      end

      response '422', 'invalid query' do
        schema '$ref' => '#/components/schemas/ErrorResponse'
        let(:month) { 'invalid' }
        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/ErrorResponse'

        let(:'X-Api-Key') { 'invalid-key' }

        run_test!
      end
    end
  end
end
