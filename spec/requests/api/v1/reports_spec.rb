# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'API V1 Reports', type: :request do
  let(:family) do
    Family.create!(
      name: 'API Family',
      currency: 'PKR',
      locale: 'en',
      date_format: '%d-%m-%Y'
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

  let(:account) do
    family.accounts.create!(
      name: 'Cash in hand',
      balance: 5000,
      currency: 'PKR',
      owner: user,
      accountable: Depository.create!(subtype: 'cash')
    )
  end

  def self.json_error
    { 'application/json' => { schema: { '$ref' => '#/components/schemas/ErrorResponse' } } }
  end

  let(:category) { family.categories.create!(name: 'Groceries', color: '#2445C8') }

  before do
    account.entries.create!(
      name: 'Doodh', date: Date.new(2026, 9, 3), amount: 2500, currency: 'PKR',
      entryable: Transaction.new(category: category)
    )
  end

  path '/api/v1/reports/export.pdf' do
    get 'Download a household report as PDF' do
      description 'Page one summarises the period (money in, money out, net and a table by label); ' \
                  'the following pages list every entry grouped by month with monthly subtotals. ' \
                  'Transfers between own accounts and excluded rows are left out. Amounts stay in each ' \
                  "account's currency. The period may cover at most 24 months and 5,000 entries."
      tags 'Reports'
      security [ { apiKeyAuth: [] } ]
      produces 'application/pdf'

      parameter name: :start_date, in: :query, required: true,
                description: 'First day of the report (YYYY-MM-DD)',
                schema: { type: :string, format: :date }
      parameter name: :end_date, in: :query, required: true,
                description: 'Last day of the report (YYYY-MM-DD)',
                schema: { type: :string, format: :date }
      parameter name: :'category_ids[]', in: :query, required: false,
                description: 'Only these labels (categories) and their sublabels. Omit for every label.',
                schema: { type: :array, items: { type: :string, format: :uuid } }
      parameter name: :include_uncategorized, in: :query, required: false,
                description: 'Include unlabelled rows. Defaults to true when category_ids is omitted, false otherwise.',
                schema: { type: :boolean }
      parameter name: :'account_ids[]', in: :query, required: false,
                description: 'Only these accounts. Omit for every account the user can see.',
                schema: { type: :array, items: { type: :string, format: :uuid } }

      let(:start_date) { '2026-09-01' }
      let(:end_date) { '2026-09-30' }

      response '200', 'report generated (application/pdf attachment)' do
        run_test!
      end

      response '422', 'invalid period, label or account' do
        metadata[:response][:content] = json_error

        let(:end_date) { '2028-09-30' }

        run_test!
      end

      response '401', 'unauthorized' do
        metadata[:response][:content] = json_error

        let(:'X-Api-Key') { 'invalid' }

        run_test!
      end
    end
  end
end
