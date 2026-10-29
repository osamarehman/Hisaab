# frozen_string_literal: true

# A write the in-app assistant proposed but the user has not confirmed yet.
# Chats created from the mobile app set confirm_writes, so their write tools
# store one of these instead of saving, and the app's confirm card applies it.
class CreatePendingAssistantActions < ActiveRecord::Migration[8.1]
  def change
    create_table :pending_assistant_actions, id: :uuid do |t|
      t.references :chat, null: false, foreign_key: { on_delete: :cascade }, type: :uuid
      t.references :family, null: false, foreign_key: { on_delete: :cascade }, type: :uuid
      t.references :user, null: false, foreign_key: { on_delete: :cascade }, type: :uuid
      t.references :message, foreign_key: { on_delete: :nullify }, type: :uuid
      t.string :provider_call_id
      t.string :function_name, null: false
      t.jsonb :arguments, null: false, default: {}
      t.string :kind, null: false
      t.string :status, null: false, default: "pending"
      t.string :summary, null: false
      t.jsonb :details, null: false, default: {}
      t.jsonb :result
      t.string :error
      t.datetime :applied_at
      t.timestamps
    end

    add_index :pending_assistant_actions, [ :chat_id, :status ]

    add_column :chats, :confirm_writes, :boolean, null: false, default: false

    # The statement a user message attached; one attachment per chat and import.
    add_reference :messages, :import, type: :uuid, foreign_key: { on_delete: :nullify }, index: false
    add_index :messages, [ :chat_id, :import_id ], unique: true, where: "import_id IS NOT NULL"
  end
end
