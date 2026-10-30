# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'API V1 AI Settings', type: :request do
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
      password_confirmation: 'password123',
      role: 'admin'
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

  let(:'X-Api-Key') { api_key.plain_key }

  # Documentation only: keep the connection test off the network.
  before do
    allow_any_instance_of(Provider::Openai).to receive(:test_connection)
      .and_return(Provider::Response.new(success?: true, data: 'OK', error: nil))
  end

  path '/api/v1/ai_settings' do
    get 'Retrieve the household AI key settings' do
      description 'Whether the household brings its own OpenAI-compatible LLM key. The key itself is never returned.'
      tags 'AI Settings'
      security [ { apiKeyAuth: [] } ]
      produces 'application/json'

      response '200', 'settings retrieved' do
        schema '$ref' => '#/components/schemas/AiSettings'

        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/ErrorResponse'

        let(:'X-Api-Key') { nil }

        run_test!
      end
    end

    put 'Save the household AI key' do
      description 'Family admins only. Stores an OpenAI-compatible key, base URL and model for every AI feature of the household. A preset fills in a blank base URL or model.'
      tags 'AI Settings'
      security [ { apiKeyAuth: [] } ]
      consumes 'application/json'
      produces 'application/json'
      parameter name: :body, in: :body, required: true, schema: { '$ref' => '#/components/schemas/AiSettingsInput' }

      response '200', 'settings saved' do
        schema '$ref' => '#/components/schemas/AiSettings'

        let(:body) { { preset: 'gemini', api_key: 'AIzaExampleKey' } }

        run_test!
      end

      response '422', 'invalid settings' do
        schema '$ref' => '#/components/schemas/ErrorResponse'

        let(:body) { { api_key: 'key', base_url: 'http://example.com/v1', model: 'm' } }

        run_test!
      end
    end

    delete 'Remove the household AI key' do
      description 'Family admins only. The household falls back to the server\'s AI configuration.'
      tags 'AI Settings'
      security [ { apiKeyAuth: [] } ]
      produces 'application/json'

      response '200', 'key removed' do
        schema '$ref' => '#/components/schemas/AiSettings'

        run_test!
      end
    end
  end

  path '/api/v1/ai_settings/test' do
    post 'Test an AI key' do
      description 'Family admins only. Sends one tiny completion with the given settings (or the stored ones) and reports the provider\'s answer or error.'
      tags 'AI Settings'
      security [ { apiKeyAuth: [] } ]
      consumes 'application/json'
      produces 'application/json'
      parameter name: :body, in: :body, required: true, schema: { '$ref' => '#/components/schemas/AiSettingsInput' }

      response '200', 'connection works' do
        schema '$ref' => '#/components/schemas/AiSettingsTestResult'

        let(:body) { { preset: 'gemini', api_key: 'AIzaExampleKey' } }

        run_test!
      end

      response '422', 'connection failed' do
        schema '$ref' => '#/components/schemas/AiSettingsTestResult'

        let(:body) { { api_key: 'key', base_url: 'http://example.com/v1', model: 'm' } }

        run_test!
      end
    end
  end
end
