class CreateBankAlerts < ActiveRecord::Migration[8.1]
  def change
    create_table :email_inboxes, id: :uuid do |t|
      t.references :family, null: false, foreign_key: true, type: :uuid, index: { unique: true }
      t.string :token, null: false
      t.datetime :rotated_at, null: false
      t.string :confirmation_code
      t.string :confirmation_url
      t.datetime :confirmation_received_at
      t.timestamps
    end
    add_index :email_inboxes, :token, unique: true

    create_table :email_senders, id: :uuid do |t|
      t.references :family, null: false, foreign_key: true, type: :uuid
      t.string :pattern, null: false
      t.timestamps
    end
    add_index :email_senders, [ :family_id, :pattern ], unique: true

    create_table :bank_alerts, id: :uuid do |t|
      t.references :family, null: false, foreign_key: true, type: :uuid
      t.references :inbound_email, foreign_key: { to_table: :action_mailbox_inbound_emails, on_delete: :nullify }, type: :uuid
      t.string :message_id, null: false
      t.string :status, null: false
      t.string :from_address
      t.string :subject
      t.datetime :received_at, null: false
      t.string :parser
      t.decimal :amount, precision: 19, scale: 4
      t.string :currency
      t.string :direction
      t.string :last4
      t.datetime :occurred_at
      t.string :payee
      t.references :account, foreign_key: { on_delete: :nullify }, type: :uuid
      t.references :entry, foreign_key: { on_delete: :nullify }, type: :uuid
      t.string :error
      t.timestamps
    end
    add_index :bank_alerts, [ :family_id, :message_id ], unique: true
    add_index :bank_alerts, [ :family_id, :status, :received_at ]

    add_column :accounts, :number_last4, :string
  end
end
