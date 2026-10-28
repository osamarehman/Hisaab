# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'API V1 Passkeys', type: :request do
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

  let!(:passkey) do
    user.webauthn_credentials.create!(nickname: 'Pixel 8', credential_id: 'docs-credential', public_key: 'docs-key')
  end

  step_up_properties = {
    code: { type: :string, nullable: true, description: 'Authenticator or backup code (when two-factor authentication is on)' },
    password: { type: :string, nullable: true, description: 'Account password (when two-factor authentication is off)' }
  }

  path '/api/v1/passkeys' do
    get 'List passkeys' do
      tags 'Passkeys'
      security [ { apiKeyAuth: [] } ]
      produces 'application/json'
      description "Lists the signed-in user's passkeys and which step-up adding a new one needs."

      response '200', 'passkeys listed' do
        schema '$ref' => '#/components/schemas/PasskeyCollection'
        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/ErrorResponse'
        let(:'X-Api-Key') { nil }
        run_test!
      end
    end

    post 'Register a passkey' do
      tags 'Passkeys'
      security [ { apiKeyAuth: [] } ]
      consumes 'application/json'
      produces 'application/json'
      description 'Saves the credential the device created for the options from POST /api/v1/passkeys/options. ' \
                  'The step-up is checked again and spent here.'
      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        properties: step_up_properties.merge(
          challenge: { type: :string, description: 'The challenge from the registration options' },
          credential: { '$ref' => '#/components/schemas/WebauthnCredential' },
          nickname: { type: :string, nullable: true, description: 'Name shown in the passkey list' }
        ),
        required: %w[challenge credential]
      }

      let(:body) { { challenge: 'unknown', credential: { id: 'x', rawId: 'x', type: 'public-key', response: {} }, password: 'password123' } }

      response '201', 'passkey registered' do
        schema '$ref' => '#/components/schemas/Passkey'
        run_test!
      end

      response '422', 'challenge, credential or step-up rejected' do
        schema '$ref' => '#/components/schemas/ErrorResponse'
        run_test!
      end
    end
  end

  path '/api/v1/passkeys/options' do
    post 'Get passkey registration options' do
      tags 'Passkeys'
      security [ { apiKeyAuth: [] } ]
      consumes 'application/json'
      produces 'application/json'
      description 'Checks the step-up without spending it and returns WebAuthn PublicKeyCredentialCreationOptions ' \
                  'for a discoverable, user-verified passkey. The challenge is single-use and expires after 5 minutes.'
      parameter name: :body, in: :body, required: true, schema: { type: :object, properties: step_up_properties }

      let(:body) { { password: 'password123' } }

      response '200', 'registration options' do
        schema type: :object, additionalProperties: true,
               properties: {
                 challenge: { type: :string },
                 rp: { type: :object, properties: { id: { type: :string }, name: { type: :string } } },
                 user: { type: :object, properties: { id: { type: :string }, name: { type: :string }, displayName: { type: :string } } }
               }
        run_test!
      end

      response '403', 'the account has neither a password nor two-factor authentication to confirm with' do
        schema '$ref' => '#/components/schemas/ErrorResponse'
        run_test!
      end

      response '422', 'wrong password or code' do
        schema '$ref' => '#/components/schemas/ErrorResponse'
        let(:body) { { password: 'wrong' } }
        run_test!
      end
    end
  end

  path '/api/v1/passkeys/{id}' do
    parameter name: :id, in: :path, type: :string, required: true, description: 'Passkey ID'

    delete 'Remove a passkey' do
      tags 'Passkeys'
      security [ { apiKeyAuth: [] } ]

      let(:id) { passkey.id }

      response '204', 'passkey removed' do
        run_test!
      end

      response '404', 'passkey not found' do
        let(:id) { SecureRandom.uuid }
        run_test!
      end
    end
  end
end
