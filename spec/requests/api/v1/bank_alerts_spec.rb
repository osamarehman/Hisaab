# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'API V1 Bank alert emails', type: :request do
  let(:family) { Family.create!(name: 'API Family', currency: 'PKR', locale: 'en', date_format: '%d-%m-%Y') }
  let(:user) { family.users.create!(email: 'alerts-user@example.com', password: 'password123', password_confirmation: 'password123') }
  let(:api_key) { ApiKey.create!(user: user, name: 'API Docs Key', key: ApiKey.generate_secure_key, scopes: %w[read_write], source: 'web') }
  let(:'X-Api-Key') { api_key.plain_key }
  let(:alert) do
    family.bank_alerts.create!(message_id: 'm1', status: 'needs_account', received_at: Time.current, from_address: 'no-reply@meezanbank.com',
                               subject: 'Debit Transaction Alert', parser: 'meezan', amount: 10_000, currency: 'PKR', direction: 'out', last4: '9483')
  end

  path '/api/v1/email_inbox' do
    get 'Show the bank alert inbox' do
      tags 'Bank alert emails'
      description 'The household\'s private forwarding address (created on first read), Gmail\'s forwarding confirmation, allowed senders and the latest alerts.'
      security [ { apiKeyAuth: [] } ]
      produces 'application/json'
      response '200', 'inbox returned' do
        schema '$ref' => '#/components/schemas/EmailInbox'
        run_test!
      end
    end
  end

  path '/api/v1/email_inbox/rotate' do
    post 'Rotate the forwarding address' do
      tags 'Bank alert emails'
      description 'Issues a new address; mail to the old one is no longer accepted.'
      security [ { apiKeyAuth: [] } ]
      produces 'application/json'
      response '200', 'inbox with a new address' do
        schema '$ref' => '#/components/schemas/EmailInbox'
        run_test!
      end
    end
  end

  path '/api/v1/email_senders' do
    get 'List allowed senders' do
      tags 'Bank alert emails'
      security [ { apiKeyAuth: [] } ]
      produces 'application/json'
      response '200', 'senders returned' do
        schema type: :object, required: %w[senders], properties: { senders: { type: :array, items: { '$ref' => '#/components/schemas/EmailSender' } } }
        run_test!
      end
    end

    post 'Allow a sender' do
      tags 'Bank alert emails'
      description 'Mail from any other sender is kept as an ignored alert and never parsed.'
      security [ { apiKeyAuth: [] } ]
      consumes 'application/json'
      produces 'application/json'
      parameter name: :body, in: :body, schema: { type: :object, required: %w[pattern], properties: { pattern: { type: :string, example: '@meezanbank.com' } } }
      response '201', 'sender allowed' do
        schema '$ref' => '#/components/schemas/EmailSender'
        let(:body) { { pattern: '@meezanbank.com' } }
        run_test!
      end
      response '422', 'not an address or domain' do
        schema '$ref' => '#/components/schemas/ErrorResponse'
        let(:body) { { pattern: 'nope' } }
        run_test!
      end
    end
  end

  path '/api/v1/email_senders/{id}' do
    parameter name: :id, in: :path, type: :string, format: :uuid
    delete 'Remove an allowed sender' do
      tags 'Bank alert emails'
      security [ { apiKeyAuth: [] } ]
      response '204', 'sender removed' do
        let(:id) { family.email_senders.create!(pattern: '@meezanbank.com').id }
        run_test!
      end
    end
  end

  path '/api/v1/bank_alerts' do
    get 'List bank alerts' do
      tags 'Bank alert emails'
      description 'Alerts parsed from forwarded bank emails, newest first.'
      security [ { apiKeyAuth: [] } ]
      produces 'application/json'
      parameter name: :status, in: :query, required: false, schema: { type: :string, enum: %w[pending needs_account unparsed ignored approved rejected] }
      parameter name: :page, in: :query, required: false, schema: { type: :integer }
      parameter name: :per_page, in: :query, required: false, schema: { type: :integer }
      response '200', 'alerts returned' do
        schema type: :object, required: %w[bank_alerts pagination],
               properties: { bank_alerts: { type: :array, items: { '$ref' => '#/components/schemas/BankAlert' } }, pagination: { '$ref' => '#/components/schemas/Pagination' } }
        run_test!
      end
    end
  end

  path '/api/v1/bank_alerts/{id}/approve' do
    parameter name: :id, in: :path, type: :string, format: :uuid
    post 'Approve an alert' do
      tags 'Bank alert emails'
      description 'Posts a pending alert\'s transaction, or for needs_account creates it on account_id (and saves that account\'s last four digits when it has none).'
      security [ { apiKeyAuth: [] } ]
      consumes 'application/json'
      produces 'application/json'
      parameter name: :body, in: :body, required: false,
                schema: { type: :object, properties: { account_id: { type: :string, format: :uuid }, category_id: { type: :string, format: :uuid }, name: { type: :string } } }
      response '200', 'alert approved' do
        schema '$ref' => '#/components/schemas/BankAlert'
        let(:id) { alert.id }
        let(:body) { { account_id: family.accounts.create!(name: 'Meezan', currency: 'PKR', balance: 0, accountable: Depository.new).id } }
        run_test!
      end
      response '422', 'alert can\'t be approved as asked' do
        schema '$ref' => '#/components/schemas/ErrorResponse'
        let(:id) { alert.id }
        let(:body) { {} }
        run_test!
      end
    end
  end

  path '/api/v1/bank_alerts/{id}/reject' do
    parameter name: :id, in: :path, type: :string, format: :uuid
    post 'Reject an alert' do
      tags 'Bank alert emails'
      description 'Deletes the alert\'s pending transaction, if any.'
      security [ { apiKeyAuth: [] } ]
      produces 'application/json'
      response '200', 'alert rejected' do
        schema '$ref' => '#/components/schemas/BankAlert'
        let(:id) { alert.id }
        run_test!
      end
    end
  end
end
