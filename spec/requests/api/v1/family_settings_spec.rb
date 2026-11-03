# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'API V1 Family Settings', type: :request do
  let(:family) do
    Family.create!(
      name: 'API Family',
      currency: 'USD',
      locale: 'en',
      date_format: '%m-%d-%Y',
      country: 'US',
      timezone: 'America/New_York',
      month_start_day: 1
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
      display_key: key,
      scopes: %w[read_write],
      source: 'web'
    )
  end

  let(:api_key_without_read_scope) do
    key = ApiKey.generate_secure_key
    # Empty scopes intentionally bypass validation so the 403 response can be documented.
    ApiKey.new(
      user: user,
      name: 'No Read Docs Key',
      key: key,
      display_key: key,
      scopes: [],
      source: 'web'
    ).tap { |api_key| api_key.save!(validate: false) }
  end

  let(:'X-Api-Key') { api_key.plain_key }

  path '/api/v1/family_settings' do
    get 'Retrieve family settings' do
      description 'Retrieve a read-only snapshot of non-secret family configuration.'
      tags 'Family Settings'
      security [ { apiKeyAuth: [] } ]
      produces 'application/json'

      response '200', 'family settings retrieved' do
        schema '$ref' => '#/components/schemas/FamilySettings'

        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/ErrorResponse'

        let(:'X-Api-Key') { nil }

        run_test!
      end

      response '403', 'insufficient scope' do
        schema '$ref' => '#/components/schemas/ErrorResponse'

        let(:'X-Api-Key') { api_key_without_read_scope.plain_key }

        run_test!
      end
    end

    patch 'Update family settings' do
      description 'Change the household currency. Family admins only; requires the read_write scope.'
      tags 'Family Settings'
      security [ { apiKeyAuth: [] } ]
      consumes 'application/json'
      produces 'application/json'
      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        properties: {
          currency: { type: :string, description: 'ISO 4217 currency code, case-insensitive', example: 'USD' }
        },
        required: %w[currency]
      }

      let(:body) { { currency: 'EUR' } }

      before { user.update!(role: 'admin') }

      response '200', 'family settings updated' do
        schema '$ref' => '#/components/schemas/FamilySettings'

        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/ErrorResponse'

        let(:'X-Api-Key') { nil }

        run_test!
      end

      response '403', 'insufficient scope or not a family admin' do
        schema '$ref' => '#/components/schemas/ErrorResponse'

        let(:'X-Api-Key') { api_key_without_read_scope.plain_key }

        run_test!
      end

      response '422', 'unknown currency code' do
        schema '$ref' => '#/components/schemas/ErrorResponse'

        let(:body) { { currency: 'XYZ' } }

        run_test!
      end
    end
  end
end
