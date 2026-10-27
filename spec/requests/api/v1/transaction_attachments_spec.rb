# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'API V1 Transaction Attachments', type: :request do
  let(:family) do
    Family.create!(
      name: 'API Family',
      currency: 'PKR',
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

  let(:account) do
    Account.create!(
      family: family,
      owner: user,
      name: 'Cash',
      balance: 1000,
      currency: 'PKR',
      accountable: Depository.create!
    )
  end

  let!(:transaction) do
    account.entries.create!(
      name: 'Bazaar run',
      date: Date.current,
      amount: 1500,
      currency: 'PKR',
      entryable: Transaction.new
    ).transaction
  end

  let(:attachment) do
    transaction.attachments.attach(io: StringIO.new('receipt'), filename: 'bill.jpg', content_type: 'image/jpeg')
    transaction.attachments.last
  end

  path '/api/v1/transactions/{transaction_id}/attachments' do
    parameter name: :transaction_id, in: :path, type: :string, required: true, description: 'Transaction ID'

    post 'Upload transaction attachments' do
      description 'Attach receipts or other files (JPEG, PNG, WebP, GIF or PDF; 10MB each; at most 10 per transaction). ' \
                  'Returns the full transaction, including its attachments.'
      tags 'Transaction Attachments'
      security [ { apiKeyAuth: [] } ]
      consumes 'multipart/form-data'
      produces 'application/json'
      metadata[:operation][:requestBody] = {
        required: true,
        content: {
          'multipart/form-data' => {
            schema: {
              type: :object,
              required: %w[attachments[]],
              properties: {
                'attachments[]': {
                  type: :array,
                  items: { type: :string, format: :binary },
                  description: 'One or more files'
                }
              }
            }
          }
        }
      }

      let(:transaction_id) { transaction.id }

      response '422', 'no files, unsupported type, too large, or over the limit' do
        schema '$ref' => '#/components/schemas/ErrorResponse'

        run_test!
      end

      response '404', 'transaction not found' do
        schema '$ref' => '#/components/schemas/ErrorResponse'

        let(:transaction_id) { SecureRandom.uuid }

        run_test!
      end
    end
  end

  path '/api/v1/transactions/{transaction_id}/attachments/{id}' do
    parameter name: :transaction_id, in: :path, type: :string, required: true, description: 'Transaction ID'
    parameter name: :id, in: :path, type: :string, required: true, description: 'Attachment ID'

    let(:transaction_id) { transaction.id }
    let(:id) { attachment.id }

    get 'Download a transaction attachment' do
      description 'Streams the file. This is the `url` given for each attachment in transaction JSON.'
      tags 'Transaction Attachments'
      security [ { apiKeyAuth: [] } ]
      produces 'application/octet-stream'

      response '200', 'file streamed' do
        run_test!
      end

      response '404', 'attachment not found' do
        schema '$ref' => '#/components/schemas/ErrorResponse'

        let(:id) { SecureRandom.uuid }

        run_test!
      end
    end

    delete 'Delete a transaction attachment' do
      tags 'Transaction Attachments'
      security [ { apiKeyAuth: [] } ]
      produces 'application/json'

      response '204', 'attachment deleted' do
        run_test!
      end

      response '404', 'attachment not found' do
        schema '$ref' => '#/components/schemas/ErrorResponse'

        let(:id) { SecureRandom.uuid }

        run_test!
      end
    end
  end
end
