# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'API V1 Assistant actions', type: :request do
  let(:family) do
    Family.create!(name: 'API Family', currency: 'PKR', locale: 'en', date_format: '%Y-%m-%d')
  end

  let(:user) do
    family.users.create!(
      email: 'assistant-actions@example.com',
      password: 'password123',
      password_confirmation: 'password123',
      ai_enabled: true
    )
  end

  let(:api_key) do
    ApiKey.create!(user: user, name: 'API Docs Key', key: ApiKey.generate_secure_key, scopes: %w[read_write], source: 'web')
  end

  let(:'X-Api-Key') { api_key.plain_key }

  let(:account) do
    family.accounts.create_and_sync(
      { name: 'Cash in hand', accountable_type: 'Depository', subtype: 'cash', balance: 5000, currency: 'PKR', owner: user, accountable_attributes: {} },
      opening_balance_date: 1.year.ago.to_date
    )
  end

  let(:chat) { user.chats.create!(title: 'Kharcha', confirm_writes: true) }

  let(:pending_action) do
    result = PendingAssistantAction.propose!(
      chat: chat,
      function: Assistant::Function::CreateTransaction.new(user),
      arguments: { 'account_id' => account.id, 'date' => Date.current.iso8601, 'amount' => 2500, 'type' => 'expense', 'name' => 'Sabzi' }
    )
    PendingAssistantAction.find(result[:pending_action_id])
  end

  let(:chat_id) { chat.id }

  path '/api/v1/chats/{chat_id}/pending_actions/confirm' do
    parameter name: :chat_id, in: :path, type: :string, required: true, description: 'Chat ID'

    post 'Save proposed assistant actions' do
      tags 'Chat Actions'
      description 'Applies the listed pending actions (the confirm card\'s Save / Save all). Idempotent: applied or ' \
                  'cancelled actions are returned unchanged. A failing action comes back with status failed and an error. ' \
                  'Statement lines of one import are published together; its other open lines are cancelled.'
      security [ { apiKeyAuth: [] } ]
      consumes 'application/json'
      produces 'application/json'

      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        required: %w[ids],
        properties: { ids: { type: :array, items: { type: :string, format: :uuid }, maxItems: 200 } }
      }

      response '200', 'actions applied' do
        schema '$ref' => '#/components/schemas/PendingActionCollection'

        let(:body) { { ids: [ pending_action.id ] } }

        run_test!
      end

      response '404', 'chat or action not found' do
        schema '$ref' => '#/components/schemas/ErrorResponse'

        let(:body) { { ids: [ SecureRandom.uuid ] } }

        run_test!
      end

      response '422', 'no ids' do
        schema '$ref' => '#/components/schemas/ErrorResponse'

        let(:body) { { ids: [] } }

        run_test!
      end
    end
  end

  path '/api/v1/chats/{chat_id}/pending_actions/cancel' do
    parameter name: :chat_id, in: :path, type: :string, required: true, description: 'Chat ID'

    post 'Cancel proposed assistant actions' do
      tags 'Chat Actions'
      description 'Cancels the listed pending actions (Cancel, or removing one statement line). Nothing is written.'
      security [ { apiKeyAuth: [] } ]
      consumes 'application/json'
      produces 'application/json'

      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        required: %w[ids],
        properties: { ids: { type: :array, items: { type: :string, format: :uuid }, maxItems: 200 } }
      }

      response '200', 'actions cancelled' do
        schema '$ref' => '#/components/schemas/PendingActionCollection'

        let(:body) { { ids: [ pending_action.id ] } }

        run_test!
      end
    end
  end

  path '/api/v1/chats/{chat_id}/statements' do
    parameter name: :chat_id, in: :path, type: :string, required: true, description: 'Chat ID'

    post 'Attach a statement to the chat' do
      tags 'Chat Actions'
      description 'Hands a statement uploaded with POST /api/v1/imports (PdfImport or TransactionImport, with an account) ' \
                  'to the chat. The user message is returned at once; once the import is read the assistant posts a ' \
                  'message with one statement_entry pending action per line (suggested label, duplicate flag). ' \
                  'An import can be attached to a chat once (422 already_attached).'
      security [ { apiKeyAuth: [] } ]
      consumes 'application/json'
      produces 'application/json'

      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        required: %w[import_id],
        properties: {
          import_id: { type: :string, format: :uuid },
          file_name: { type: :string, description: 'Shown in the chat' }
        }
      }

      response '202', 'statement attached' do
        schema type: :object, required: %w[message], properties: { message: { '$ref' => '#/components/schemas/MessageResponse' } }

        let(:import) do
          family.imports.create!(type: 'TransactionImport', account: account, raw_file_str: "date,amount,name\n2026-10-01,-500,Sabzi\n").tap(&:generate_rows_from_csv)
        end
        let(:body) { { import_id: import.id, file_name: 'october.csv' } }

        run_test!
      end

      response '404', 'import not found' do
        schema '$ref' => '#/components/schemas/ErrorResponse'

        let(:body) { { import_id: SecureRandom.uuid } }

        run_test!
      end
    end
  end

  path '/api/v1/chats/{chat_id}/voice_notes' do
    parameter name: :chat_id, in: :path, type: :string, required: true, description: 'Chat ID'

    post 'Send a voice note' do
      tags 'Chat Actions'
      description 'Transcribes the audio on the server (AI_TRANSCRIBE_MODEL over the OpenAI-compatible provider; ' \
                  'Urdu, English and Roman Urdu) and posts the transcript as the user\'s message, which the assistant ' \
                  'then answers. Up to 5 MB and 120 seconds, 20 notes per user per hour (429 rate_limited); WAV 16 kHz mono recommended (mp3, m4a, aac, ogg, flac accepted).'
      security [ { apiKeyAuth: [] } ]
      consumes 'multipart/form-data'
      produces 'application/json'
      # rswag documents the first formData parameter's schema as the whole
      # multipart body, so the one parameter carries both fields.
      parameter name: :audio, in: :formData, required: true, schema: {
        type: :object,
        required: %w[audio],
        properties: {
          audio: { type: :string, format: :binary },
          duration_ms: { type: :integer, description: 'Recording length, used when the format has no readable header' }
        }
      }

      response '201', 'voice note transcribed and sent' do
        schema type: :object,
               required: %w[transcript message],
               properties: {
                 transcript: { type: :string },
                 message: { '$ref' => '#/components/schemas/MessageResponse' }
               }

        before do
          allow_any_instance_of(Assistant::VoiceNote).to receive(:transcribe!).and_return('aaj 2500 ki sabzi li')
        end

        let(:audio) { Rack::Test::UploadedFile.new(StringIO.new('RIFF'), 'audio/wav', true, original_filename: 'voice.wav') }

        run_test!
      end

      response '422', 'invalid, too long, too large, or not transcribable' do
        schema '$ref' => '#/components/schemas/ErrorResponse'

        let(:audio) { nil }

        run_test!
      end
    end
  end
end
